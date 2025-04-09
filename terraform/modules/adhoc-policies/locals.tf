# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

locals {
  name_prefix = var.name_prefix == "" ? "" : "${var.name_prefix}-"

  adhoc = {
    for path, accesses_values in var.accesses :
    path => accesses_values if accesses_values["type"] == "vault"
  }

  # Inverse the access to "auth -> secrets"
  adhoc_policies_list = flatten([
    for path, values in local.adhoc : [
      for role_name, role in values["roles"] : [
        for access in role["access"] : {
          "role_name" : role_name,
          "key" : "${local.name_prefix}${role_name}-${element(split("/", path), -1)}${try(role["for_each"], false) ? "-${replace(access, ".", "-")}" : ""}",
          "resource_name" : element(split("/", path), -1),
          "access" : access,
          "for_each" : try(role["for_each"], false),
        }
      ]
    ]
  ])

  # Keep the data relevant for Vault Policies (remove accesses)
  adhoc_policies = {
    for k in distinct([
      for l in local.adhoc_policies_list : merge([l, { "access" = null }]...)
    ]) : k["key"] => k
    if k["for_each"] == false
  }

  # Create a map with access as part of the key,
  # for roles that require new policy - per access
  adhoc_policies_for_each = {
    for p in local.adhoc_policies_list :
    p["key"] => p
    if p["for_each"] == true
  }
}
