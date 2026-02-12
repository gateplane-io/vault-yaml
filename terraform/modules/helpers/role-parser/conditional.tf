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
  conditional_roles_list = flatten([
    for path, values in local.accesses : [
      for role_name, role in values["roles"] :
      merge(
        {
          "path" : path,
          "role_name" : role_name,
          "key" : "${local.name_prefix}${values["type"]}-${role_name}-${element(split("/", path), -1)}",
          "resource_name" : element(split("/", path), -1),
          "access_requestors" : role["access"]["conditional"]["requestors"],
          "access_approvers" : role["access"]["conditional"]["approvers"],
          "access_conditional" : {
            "required_approvals" : try(role["access"]["conditional"]["required_approvals"], 1),
            "require_justification" : try(role["access"]["conditional"]["require_justification"], false),
          },
        },
        {
          for k, v in var.field_defaults :
          k => try(role[k], v)
        }
      ) if try(role["access"]["conditional"] != {}, false)
    ]
    if try(length(values["roles"]) != 0, false)
  ])

  conditional_roles = {
    for item in local.conditional_roles_list :
    item["key"] => item
  }


}
