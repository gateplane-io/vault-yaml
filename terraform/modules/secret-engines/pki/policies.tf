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
  for_each = local.policies

  rule {
    description = "Generate Certificate for '${each.value["role_name"]}' in '${each.value["resource_name"]}'"

    path         = "${each.value["path"]}/issue/${each.value["role_name"]}"
    capabilities = ["read", "update"]
  }

  rule {
    description = "Sign Certificate for '${each.value["role_name"]}' in '${each.value["resource_name"]}'"

    path         = "${each.value["path"]}/sign/${each.value["role_name"]}"
    capabilities = ["read", "update"]
  }

  rule {
    description = "[UI] List Certificate Roles"

    path         = "${each.value["path"]}/roles"
    capabilities = ["read", "list"]
  }

  rule {
    description = "[UI] Read Certificate Role"

    path         = "${each.value["path"]}/roles/${each.value["role_name"]}"
    capabilities = ["read", "list"]
  }

  rule {
    description = "[UI] Read CA"

    path         = each.value["path"]
    capabilities = ["read", "list"]
  }
}

resource "vault_policy" "this" {
  for_each = data.vault_policy_document.this

  name   = each.key
  policy = each.value.hcl
}
