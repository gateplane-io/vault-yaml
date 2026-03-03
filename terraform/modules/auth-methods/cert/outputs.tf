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
  description = "The key used in principals to identify this auth method (e.g., 'userpass')."
  value       = var.principal_key
}

output "accessor" {
  description = "The accessor for the Userpass auth method mount."
  value       = var.mount.accessor
}

output "path" {
  description = "The mount path of the Userpass auth method."
  value       = var.mount.path
}

output "entry" {
  description = "A map containing both the accessor and path of the Userpass auth method."
  value = {
    "accessor" : var.mount.accessor,
    "path" : var.mount.path,
  }
}

output "authorizations" {
  description = "The mapping of LDAP groups and users to their assigned policies for this auth method."
  value = {
    (var.principal_key) = local.authorizations
  }
}
