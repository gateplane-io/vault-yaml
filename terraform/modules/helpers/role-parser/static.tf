# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

# Create a local variable that holds the name prefix
locals {
  name_prefix = var.name_prefix == "" ? "" : "${var.name_prefix}-"
}

# Process regular roles and extract the specified fields with defaults
locals {
  accesses = {
    for path, accesses_values in var.accesses :
    path => accesses_values
    if path == var.path
  }

  static_roles_list = flatten([
    for path, values in local.accesses : [
      for role_name, role in values["roles"] : flatten([
        [for access in role["access"]["static"] : merge(
          {
            "path" : path,
            "role_name" : role_name,
            "key" : "${local.name_prefix}${values["type"]}-${role_name}-${element(split("/", path), -1)}${try(role["for_each"], false) ? "-${split(".", access)[2]}" : ""}",
            "resource_name" : element(split("/", path), -1),
            "access" : access,
          },
          {
            for k, v in var.field_defaults :
            k => try(role[k], v)
          }
          )
      ]]) if try(role["access"]["static"] != [], false)
    ]
    if try(length(values["roles"]) != 0, false)
  ])

  roles_list = flatten([local.static_roles_list, local.conditional_roles_list])
  # Keep the data relevant for Vault Policies (remove accesses)
  policies_map = {
    for k in distinct([
      for l in flatten([local.roles_list, local.conditional_roles_list]) : merge([l, {
        "access"             = null,
        "access_requestors"  = null,
        "access_approvers"   = null,
        "access_conditional" = null,
      }]...)
    ]) : k["key"] => k
  }
}
