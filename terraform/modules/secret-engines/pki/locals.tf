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

  # Inverse the access to "auth -> secrets"
  policies_list = flatten([
    for path, values in local.selected : [
      for role_name, role in values["roles"] : [
        for access in role["access"] : {
          "path" : path,
          "role_name" : role_name,
          "key" : "${local.name_prefix}${values["type"]}-${role_name}-${element(split("/", path), -1)}",
          "resource_name" : element(split("/", path), -1),
          "access" : access,

          "ttl" : try(role["ttl"], 10 * 60),
          "organization" : try(role["organization"], [])
          "country" : try(role["country"], [])
          "locality" : try(role["locality"], [])
          "key_usage" : try(role["key_usage"], ["DigitalSignature", "KeyAgreement", "KeyEncipherment"])
          "ext_key_usage" : try(role["ext_key_usage"], [])
          "allowed_domains" : try(role["allowed_domains"], [])
          "templated_common_name" : try(role["templated_common_name"], [])
          "client_flag" : try(role["client_flag"], true)
          "server_flag" : try(role["server_flag"], false)
        }
      ]
    ]
  ])

  # Keep the data relevant for Vault Policies (remove accesses)
  policies = {
    for k in distinct([
      for l in local.policies_list : merge([l, { "access" = null }]...)
    ]) : k["key"] => k
  }
}
