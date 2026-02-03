# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

data "vault_policy_document" "ssh" {
  for_each = local.policies_map

  rule {
    description = "SSH access to role '${each.value["role_name"]}' in '${each.value["resource_name"]}' CA"

    path         = "${each.value["path"]}/sign/${each.value["role_name"]}"
    capabilities = ["update"]
  }

  rule {
    description = "SSH list and read all roles"

    path         = "${each.value["path"]}/roles/*"
    capabilities = ["list", "read"]
  }

}

resource "vault_policy" "ssh" {
  for_each = data.vault_policy_document.ssh

  name   = each.key
  policy = each.value.hcl
}
