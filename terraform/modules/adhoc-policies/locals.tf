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

  roles_list = module.parser.roles_list

  # Keep the data relevant for Vault Policies (remove accesses)
  adhoc_policies = {
    for k in distinct([
      for l in local.roles_list : merge([l, { "access" = null }]...)
    ]) : k["key"] => k
    if k["for_each"] == false
  }

  # Create a map with access as part of the key,
  # for roles that require new policy - per access
  adhoc_policies_for_each = {
    for p in local.roles_list :
    p["key"] => p
    if p["for_each"] == true
  }
}
