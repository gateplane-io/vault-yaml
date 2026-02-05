# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

module "gateplane" {
  count  = var.enable_conditional_roles ? 1 : 0
  source = "../../../modules/conditional-access"

  name_prefix = var.name_prefix

  roles_conditional = module.parser.roles_list_conditional
  policies          = vault_policy.this
}
