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
  description = "The Vault policies created for SSH roles."
  value       = vault_policy.this
}

output "access_list" {
  description = "The flattened list of all SSH access policies, including both static and conditional access policies  (if enabled)."
  value       = flatten([local.roles_list, try(module.gateplane[0].access_list, [])])
}

output "entry" {
  description = "A map containing the mount path and accessor for the SSH secrets engine."
  value = {
    "path"     = var.mount.path,
    "accessor" = var.mount.accessor,
  }
}
