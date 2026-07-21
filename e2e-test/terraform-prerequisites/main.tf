# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_mount" "kv" {
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "E2E KV v2 prerequisite"
}

resource "vault_mount" "pki" {
  path                      = "pki/org-ca"
  type                      = "pki"
  description               = "E2E root CA prerequisite"
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 31536000
}

resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on = [vault_mount.pki]

  backend              = vault_mount.pki.path
  type                 = "internal"
  common_name          = "vault-yaml E2E root"
  organization         = "vault-yaml E2E"
  ttl                  = 31536000
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 2048
  exclude_cn_from_sans = true
}

resource "vault_kubernetes_secret_backend" "kubernetes" {
  path                      = "staging/cluster01"
  description               = "E2E Kubernetes secrets prerequisite"
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 3600
  kubernetes_host           = "https://kubernetes.default.svc"
}

resource "vault_mount" "ssh" {
  path        = "staging/vms"
  type        = "ssh"
  description = "E2E SSH CA prerequisite"
}

resource "vault_ssh_secret_backend_ca" "ssh" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}

resource "vault_ldap_auth_backend" "ldap" {
  path         = "ldap"
  description  = "E2E LDAP prerequisite"
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
  name = "e2e-entity"
}

resource "vault_identity_group" "named" {
  name = "e2e-identity-group"
  type = "internal"
}
