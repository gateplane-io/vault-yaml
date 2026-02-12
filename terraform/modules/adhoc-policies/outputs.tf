# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

output "policies" {
  description = "The Vault policies created for ad-hoc access configurations."
  value       = vault_policy.adhoc
}

output "access_list" {
  description = "The list of roles/access configurations defined in the adhoc-policies module."
  value       = local.roles_list
}
