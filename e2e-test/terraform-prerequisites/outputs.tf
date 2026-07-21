# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

output "mounts" {
  value = {
    kv         = { path = vault_mount.kv.path, accessor = vault_mount.kv.accessor }
    pki        = { path = vault_mount.pki.path, accessor = vault_mount.pki.accessor }
    kubernetes = { path = vault_kubernetes_secret_backend.kubernetes.path, accessor = vault_kubernetes_secret_backend.kubernetes.accessor }
    ssh        = { path = vault_mount.ssh.path, accessor = vault_mount.ssh.accessor }
  }
}

output "auth_methods" {
  value = {
    ldap       = { path = vault_ldap_auth_backend.ldap.path, accessor = vault_ldap_auth_backend.ldap.accessor }
    cert       = { path = vault_auth_backend.cert.path, accessor = vault_auth_backend.cert.accessor }
    kubernetes = { path = vault_auth_backend.kubernetes.path, accessor = vault_auth_backend.kubernetes.accessor }
  }
}

output "pki_root" {
  value = {
    issuer_id   = vault_pki_secret_backend_root_cert.root.issuer_id
    certificate = vault_pki_secret_backend_root_cert.root.certificate
  }
}

output "identity" {
  value = {
    entity_id = vault_identity_entity.named.id
    group_id  = vault_identity_group.named.id
  }
}
