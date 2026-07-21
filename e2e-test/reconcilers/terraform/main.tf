# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "prerequisite_state_path" {
  type = string
}

data "terraform_remote_state" "prerequisites" {
  backend = "local"
  config = {
    path = var.prerequisite_state_path
  }
}

locals {
  accesses     = yamldecode(file("${path.module}/../../access.yaml"))
  mounts       = data.terraform_remote_state.prerequisites.outputs.mounts
  auth_methods = data.terraform_remote_state.prerequisites.outputs.auth_methods
  pki_root     = data.terraform_remote_state.prerequisites.outputs.pki_root

  secret_engines = {
    kv         = local.mounts.kv
    pki        = module.pki.entry
    kubernetes = module.kubernetes_secrets.entry
    ssh        = module.ssh.entry
  }
}

module "pki" {
  source = "../../../terraform/modules/secrets-engines/pki"

  mount                    = local.mounts.pki
  issuer_id                = local.pki_root.issuer_id
  accesses                 = local.accesses
  enable_conditional_roles = false
  templated_common_names = {
    email = "{{identity.entity.aliases.${local.auth_methods.ldap.accessor}.name}}@example.test"
  }
}

module "kubernetes_secrets" {
  source = "../../../terraform/modules/secrets-engines/kubernetes"

  mount                    = local.mounts.kubernetes
  role_directory           = "${path.module}/../../fixtures/roles/kubernetes"
  accesses                 = local.accesses
  enable_conditional_roles = false
}

module "ssh" {
  source = "../../../terraform/modules/secrets-engines/ssh"

  mount                    = local.mounts.ssh
  accesses                 = local.accesses
  allowed_users            = "{{identity.entity.aliases.${local.auth_methods.ldap.accessor}.name}}"
  default_user             = "{{identity.entity.aliases.${local.auth_methods.ldap.accessor}.name}}"
  enable_conditional_roles = false
}

module "vault_policies" {
  source = "../../../terraform/modules/secrets-engines/vault"

  role_directory           = "${path.module}/../../fixtures/roles/vault"
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
  source = "../../../terraform/modules/auth-methods/ldap"

  mount         = local.auth_methods.ldap
  policies_list = local.policies_list
  principal_key = "ldap"
}

module "identity" {
  source = "../../../terraform/modules/auth-methods/identity"

  policies_list = local.policies_list
  principal_key = "identity"
}

module "cert" {
  source = "../../../terraform/modules/auth-methods/cert"

  mount               = local.auth_methods.cert
  trusted_certificate = local.pki_root.certificate
  policies_list       = local.policies_list
  principal_key       = "cert"
}

module "kubernetes_auth" {
  source = "../../../terraform/modules/auth-methods/kubernetes"

  mount         = local.auth_methods.kubernetes
  policies_list = local.policies_list
  principal_key = "kubernetes"
}
