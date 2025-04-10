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

  ssh = {
    for path, accesses_values in var.accesses :
    path => accesses_values if accesses_values["type"] == "ssh"
  }

  # Inverse the access to "auth -> secrets"
  ssh_policies_list = flatten([
    for path, values in local.ssh : [
      for role_name, role in values["roles"] : [
        for access in role["access"] : {
          "path" : path,
          "role_name" : role_name,
          "key" : "${local.name_prefix}${values["type"]}-${role_name}-${element(split("/", path), -1)}",
          "resource_name" : element(split("/", path), -1),
          "access" : access,
          "extensions" : try(role["extensions"], ["permit-pty"])
          "ttl" : try(role["ttl"], 1 * 60),
          "ttl_max" : try(role["ttl_max"], 10 * 60),
        }
      ]
    ]
  ])

  # Keep the data relevant for Vault Policies (remove accesses)
  ssh_policies = {
    for k in distinct([
      for l in local.ssh_policies_list : merge([l, { "access" = null }]...)
    ]) : k["key"] => k
  }
}
