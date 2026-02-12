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
  value = var.principal_key
}

output "accessor" {
  value = var.mount.accessor
}

output "path" {
  value = var.mount.path
}

output "entry" {
  value = {
    "accessor" : var.mount.accessor,
    "path" : var.mount.path,
  }
}

output "authorizations" {
  value = {
    (var.principal_key) = local.authorizations
  }
}
