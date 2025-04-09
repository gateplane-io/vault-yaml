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
  value = vault_policy.kubernetes
}

output "access_list" {
  value = local.kubernetes_policies_list
}

output "entry" {
  value = {
    "path"     = vault_kubernetes_secret_backend.this.path,
    "accessor" = vault_kubernetes_secret_backend.this.accessor,
  }
}
