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
  value = module.vault_yaml.secret_engines
}

output "auth_methods" {
  value = module.vault_yaml.auth_methods
}

output "policy_names" {
  value = sort(distinct([
    for policy in module.vault_yaml.policies_list : policy.key
  ]))
}

output "access_list" {
  value = module.vault_yaml.policies_list
}

output "authorizations" {
  value = module.vault_yaml.authorizations
}
