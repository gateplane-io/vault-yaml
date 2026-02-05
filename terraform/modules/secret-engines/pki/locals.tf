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

  selected = {
    for path, accesses_values in var.accesses :
    path => accesses_values
    if accesses_values["type"] == "pki" && path == var.path
  }

  roles_list   = module.parser.roles_list_static
  policies_map = module.parser.policies_map

}
