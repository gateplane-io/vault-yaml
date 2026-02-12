# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

output "principal_key" {
  description = "The key used in principals to identify this auth method (e.g., 'identity')."
  value       = var.principal_key
}

output "authorizations" {
  description = "The mapping of entities and groups to their assigned policies for this auth method."
  value = {
    (var.principal_key) = local.authorizations
  }
}
