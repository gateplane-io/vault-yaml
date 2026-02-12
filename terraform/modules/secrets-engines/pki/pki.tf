# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_pki_secret_backend_role" "this" {
  for_each = local.policies_map

  backend    = var.mount.path
  name       = each.value["role_name"]
  issuer_ref = var.issuer_id

  no_store    = false
  client_flag = each.value["client_flag"]
  server_flag = each.value["server_flag"]

  organization = each.value["organization"]
  country      = each.value["country"]
  locality     = each.value["locality"]

  ttl     = each.value["ttl"]
  max_ttl = each.value["ttl"]

  key_usage     = each.value["key_usage"]
  ext_key_usage = each.value["ext_key_usage"]

  allow_bare_domains = true
  allowed_domains = flatten([
    each.value["allowed_domains"],
    [for name in each.value["templated_common_name"] :
      var.templated_common_names[name]
    ]
  ])
  allowed_domains_template = length(each.value["templated_common_name"]) != 0
}
