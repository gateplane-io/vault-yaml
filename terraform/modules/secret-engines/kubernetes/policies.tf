# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

data "vault_policy_document" "this" {
  for_each = local.all_policies

  rule {
    description = "Kubernetes access to role '${each.value["role_name"]}' in '${each.value["resource_name"]}', namespaces: [${join(",", each.value["namespaces"])}]"

    path         = "${each.value["path"]}/creds/${each.value["role_name"]}"
    capabilities = ["read", "update"]
    allowed_parameter {
      key   = "kubernetes_namespace"
      value = each.value["namespaces"]
    }
  }
}

resource "vault_policy" "this" {
  for_each = data.vault_policy_document.this

  name   = each.key
  policy = each.value.hcl
}
