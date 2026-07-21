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
  matching_accesses = distinct([
    for policy in var.policies_list : policy.access
    if startswith(split("::", policy.access)[0], "${var.principal_key}.")
  ])

  principals = {
    for access in local.matching_accesses :
    trimprefix(split("::", access)[0], "${var.principal_key}.") => merge(
      {
        access    = access
        principal = trimprefix(split("::", access)[0], "${var.principal_key}.")
        parts     = slice(split(".", split("::", access)[0]), 1, length(split(".", split("::", access)[0])))
        policies = [
          for policy in var.policies_list : policy.key
          if policy.access == access
        ]
      },
      length(split("::", access)) > 1 ? {
        for pair in split(",", split("::", access)[1]) :
        split("=", pair)[0] => try(
          jsondecode(split("=", pair)[1]),
          split("=", pair)[1]
        )
      } : {}
    )
  }
}
