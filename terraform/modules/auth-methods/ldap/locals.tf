# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

module "principal_parser" {
  source = "../../helpers/principal-parser"

  policies_list = var.policies_list
  principal_key = var.principal_key
}

locals {
  authorizations = {
    groups = {
      for _, authorization in module.principal_parser.principals :
      authorization.parts[1] => authorization
      if authorization.parts[0] == "groups"
    }
    users = {
      for _, authorization in module.principal_parser.principals :
      authorization.parts[1] => authorization
      if authorization.parts[0] == "users"
    }
  }
}
