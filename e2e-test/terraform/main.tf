# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

locals {
  accesses = yamldecode(file("${path.module}/../access.yaml"))

  static_principals = distinct(flatten([
    for _, engine in local.accesses : flatten([
      for role in values(try(engine.roles, {})) : try(role.access.static, [])
    ])
  ]))

  identity_entity_names = toset([
    for principal in local.static_principals : split(".", principal)[2]
    if startswith(principal, "identity.entity_name.")
  ])
  identity_group_names = toset([
    for principal in local.static_principals : split(".", principal)[2]
    if startswith(principal, "identity.group_name.")
  ])

}

resource "vault_mount" "kv" {
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "Fixture KV v2 mount used by ad-hoc policy templates"
}

resource "vault_mount" "pki" {
  path                      = "pki/org-ca"
  type                      = "pki"
  description               = "Fixture root CA"
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 31536000
}

resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on = [vault_mount.pki]

  backend              = vault_mount.pki.path
  type                 = "internal"
  common_name          = "vault-yaml fixture root"
  organization         = "vault-yaml fixture"
  ttl                  = 31536000
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 2048
  exclude_cn_from_sans = true
}

resource "vault_kubernetes_secret_backend" "kubernetes" {
  path                      = "staging/cluster01"
  description               = "Fixture Kubernetes secrets backend"
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 3600
  kubernetes_host           = "https://kubernetes.default.svc"
}

resource "vault_mount" "ssh" {
  path        = "staging/vms"
  type        = "ssh"
  description = "Fixture SSH certificate authority"
}

resource "vault_ssh_secret_backend_ca" "ssh" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_ldap_auth_backend" "ldap" {
  path         = "ldap"
  description  = "Fixture LDAP auth backend; no live directory is required at apply time"
  url          = "ldap://127.0.0.1:389"
  userdn       = "ou=users,dc=example,dc=test"
  userattr     = "uid"
  groupdn      = "ou=groups,dc=example,dc=test"
  groupfilter  = "(&(objectClass=groupOfNames)(member={{.UserDN}}))"
  groupattr    = "cn"
  insecure_tls = true
}

resource "vault_auth_backend" "cert" {
  path = "cert"
  type = "cert"
}

resource "vault_auth_backend" "kubernetes" {
  path = "kubernetes"
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc"
  disable_iss_validation = true
}



resource "vault_identity_entity" "named" {
  for_each = local.identity_entity_names
  name     = each.key
}

resource "vault_identity_group" "named" {
  for_each = local.identity_group_names
  name     = each.key
  type     = "internal"
}



module "pki" {
  source = "../../terraform/modules/secrets-engines/pki"

  mount                    = vault_mount.pki
  issuer_id                = vault_pki_secret_backend_root_cert.root.issuer_id
  accesses                 = local.accesses
  enable_conditional_roles = false
  templated_common_names = {
    email = "{{identity.entity.aliases.${vault_ldap_auth_backend.ldap.accessor}.name}}@example.test"
  }
}

module "kubernetes_secrets" {
  source = "../../terraform/modules/secrets-engines/kubernetes"

  mount                    = vault_kubernetes_secret_backend.kubernetes
  role_directory           = "${path.module}/../fixtures/roles/kubernetes"
  accesses                 = local.accesses
  enable_conditional_roles = false
}

module "ssh" {
  source = "../../terraform/modules/secrets-engines/ssh"

  mount                    = vault_mount.ssh
  accesses                 = local.accesses
  allowed_users            = "{{identity.entity.aliases.${vault_ldap_auth_backend.ldap.accessor}.name}}"
  default_user             = "{{identity.entity.aliases.${vault_ldap_auth_backend.ldap.accessor}.name}}"
  enable_conditional_roles = false

  depends_on = [vault_ssh_secret_backend_ca.ssh]
}

locals {
  secret_engines = {
    kv = {
      path     = vault_mount.kv.path
      accessor = vault_mount.kv.accessor
    }
    pki        = module.pki.entry
    kubernetes = module.kubernetes_secrets.entry
    ssh        = module.ssh.entry
  }
  auth_methods = {
    ldap = {
      path     = vault_ldap_auth_backend.ldap.path
      accessor = vault_ldap_auth_backend.ldap.accessor
    }
    cert = {
      path     = vault_auth_backend.cert.path
      accessor = vault_auth_backend.cert.accessor
    }
    kubernetes = {
      path     = vault_auth_backend.kubernetes.path
      accessor = vault_auth_backend.kubernetes.accessor
    }

  }
}

module "vault_policies" {
  source = "../../terraform/modules/secrets-engines/vault"

  role_directory           = "${path.module}/../fixtures/roles/vault"
  accesses                 = local.accesses
  secret_engines           = local.secret_engines
  auth_methods             = local.auth_methods
  enable_conditional_roles = false
}

locals {
  policies_list = flatten([
    module.pki.access_list,
    module.kubernetes_secrets.access_list,
    module.ssh.access_list,
    module.vault_policies.access_list,
  ])
}

module "ldap" {
  source = "../../terraform/modules/auth-methods/ldap"

  mount         = vault_ldap_auth_backend.ldap
  policies_list = local.policies_list
  principal_key = "ldap"
}

module "identity" {
  source = "../../terraform/modules/auth-methods/identity"

  policies_list = local.policies_list
  principal_key = "identity"

  depends_on = [vault_identity_entity.named, vault_identity_group.named]
}

module "cert" {
  source = "../../terraform/modules/auth-methods/cert"

  mount               = vault_auth_backend.cert
  trusted_certificate = vault_pki_secret_backend_root_cert.root.certificate
  policies_list       = local.policies_list
  principal_key       = "cert"
}

module "kubernetes_auth" {
  source = "../../terraform/modules/auth-methods/kubernetes"

  mount         = vault_auth_backend.kubernetes
  policies_list = local.policies_list
  principal_key = "kubernetes"

  depends_on = [vault_kubernetes_auth_backend_config.kubernetes]
}
