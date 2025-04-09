# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_policy" "adhoc" {
  for_each = local.adhoc_policies

  name = each.key
  policy = templatefile("${var.role_directory}/${each.value["role_name"]}.hcl",
    {
      secret_engines = var.secret_engines,
      auth_methods   = var.auth_methods,
      policy_name    = each.key,
    }
  )
}


resource "vault_policy" "adhoc_for_each" {
  for_each = local.adhoc_policies_for_each

  name = each.key
  policy = templatefile("${var.role_directory}/${each.value["role_name"]}.hcl",
    {
      secret_engines = var.secret_engines,
      auth_methods   = var.auth_methods,
      access         = each.value["access"],
      policy_name    = each.key,
    }
  )
}
