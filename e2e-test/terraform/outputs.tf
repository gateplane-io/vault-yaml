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
  description = "Mount paths and accessors created by the fixture."
  value = {
    kv         = { path = vault_mount.kv.path, accessor = vault_mount.kv.accessor }
    pki        = module.pki.entry
    kubernetes = module.kubernetes_secrets.entry
    ssh        = module.ssh.entry
  }
}

output "auth_methods" {
  description = "Auth paths and accessors created by the fixture."
  value       = local.auth_methods
}

output "pki_root" {
  description = "Non-sensitive root CA values useful for assertions."
  value = {
    issuer_id   = vault_pki_secret_backend_root_cert.root.issuer_id
    certificate = vault_pki_secret_backend_root_cert.root.certificate
  }
}

output "ssh_public_key" {
  description = "SSH CA public key useful for fixture assertions."
  value       = vault_ssh_secret_backend_ca.ssh.public_key
}

output "policy_names" {
  description = "Policy names produced by all static secrets-engine modules."
  value = sort(distinct(concat(
    keys(module.pki.policies),
    keys(module.kubernetes_secrets.policies),
    keys(module.ssh.policies),
    keys(module.vault_policies.policies),
  )))
}

output "access_list" {
  description = "Combined normalized static access list passed to auth modules."
  value       = local.policies_list
}

output "authorizations" {
  description = "Parsed authorization maps from the invoked auth modules."
  value = {
    ldap       = module.ldap.authorizations
    identity   = module.identity.authorizations
    cert       = module.cert.authorizations
    kubernetes = module.kubernetes_auth.authorizations
  }
}

output "fixture_identity_names" {
  description = "Identity names materialized as prerequisites."
  value = {
    entities = sort(tolist(local.identity_entity_names))
    groups   = sort(tolist(local.identity_group_names))
  }
}
