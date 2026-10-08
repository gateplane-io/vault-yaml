# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

output "authorizations" {
  description = "Authorizations grouped by auth-method principal key."
  value       = local.authorizations
}

output "policies_list" {
  description = "Flattened access-policy metadata produced by all configured secrets-engine modules."
  value       = local.policies_list
}

output "secret_engines" {
  description = "Secrets-engine path and accessor map available to ad-hoc policy templates."
  value       = local.secret_engines
}

output "auth_methods" {
  description = "Auth-method path and accessor map available to ad-hoc policy templates."
  value       = local.auth_methods
}
