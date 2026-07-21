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
  value = local.mounts
}

output "auth_methods" {
  value = local.auth_methods
}

output "policy_names" {
  value = sort(distinct(concat(
    keys(module.pki.policies),
    keys(module.kubernetes_secrets.policies),
    keys(module.ssh.policies),
    keys(module.vault_policies.policies),
  )))
}

output "access_list" {
  value = local.policies_list
}

output "authorizations" {
  value = {
    ldap       = module.ldap.authorizations
    identity   = module.identity.authorizations
    cert       = module.cert.authorizations
    kubernetes = module.kubernetes_auth.authorizations
  }
}
