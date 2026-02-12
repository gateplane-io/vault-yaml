# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_mount" "kvv2" {
  path        = "kvv2"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_backend_v2" "kvv2" {
  mount        = vault_mount.kvv2.path
  max_versions = 2
}

resource "vault_kubernetes_secret_backend" "kubernetes" {
  path        = "staging/cluster01"
  description = "Vault testing for K8s Cluster"

  # Permissive defaults, tuned down by Role specific TTLs
  default_lease_ttl_seconds = 43200
  max_lease_ttl_seconds     = 86400

  kubernetes_host     = "https://127.0.0.1:6443"
  service_account_jwt = var.kubernetes_token
  kubernetes_ca_cert  = var.kubernetes_ca
}

resource "vault_mount" "ssh" {
  path        = "staging/vms"
  type        = "ssh"
  description = "Access staging VMs"
}

resource "vault_ssh_secret_backend_ca" "ssh" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true

  lifecycle {
    ignore_changes = [generate_signing_key]
  }
}


resource "vault_mount" "pki" {
  path                      = "pki/org-ca"
  type                      = "pki"
  description               = "The central CA of the Org"
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 86400
}

resource "vault_pki_secret_backend_root_cert" "this" {
  depends_on   = [vault_mount.pki]
  backend      = vault_mount.pki.path
  type         = "internal"
  common_name  = "Org CA"
  organization = "Org"
  # Set Verbatim End Date instead of 'ttl'
  # not_after            = "2027-01-23T18:46:42Z"
  not_after            = "2031-05-10T12:00:00Z"
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
}
