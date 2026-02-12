# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

module "parser" {
  source = "../../helpers/role-parser"

  name_prefix = var.name_prefix

  accesses = var.accesses
  path     = var.mount.path

  field_defaults = {
    "ttl" : 10 * 60

    "organization" : []
    "country" : []
    "locality" : []

    "key_usage" : ["DigitalSignature", "KeyAgreement", "KeyEncipherment"]
    "ext_key_usage" : []

    "allowed_domains" : []
    "templated_common_name" : []

    "client_flag" : true
    "server_flag" : false
  }
}
