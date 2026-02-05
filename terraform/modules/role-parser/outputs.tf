# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

output "roles_list_conditional" {
  description = "List of roles extracted from both static and conditional roles with specified fields"
  value       = local.conditional_roles_list
}

output "roles_list_static" {
  description = "List of roles extracted from both static and conditional roles with specified fields"
  value       = local.static_roles_list
}

output "roles_list" {
  description = "List of roles extracted from both static and conditional roles with specified fields"
  value       = local.roles_list
}

output "policies_map" {
  description = "Map of Policies extracted from both static and conditional roles with specified fields"
  value       = local.policies_map
}
