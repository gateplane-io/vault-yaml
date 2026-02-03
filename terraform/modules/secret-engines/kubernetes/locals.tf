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
  role_definitions = {
    for f in fileset(var.role_directory, "*.yaml") :
    trimsuffix(trimprefix(f, var.role_directory), ".yaml") => file("${var.role_directory}/${f}")
  }

  name_template = var.name_prefix == "" ? var.name_template : "${var.name_prefix}-${var.name_template}"

  roles_list   = module.parser.roles_list
  all_policies = module.parser.policies_map
}
