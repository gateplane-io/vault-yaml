# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_mount" "this" {
  description               = var.description
  type                      = "pki"
  path                      = var.path
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 86400
}

resource "vault_pki_secret_backend_root_cert" "this" {
  depends_on  = [vault_mount.this]
  backend     = vault_mount.this.path
  type        = "internal"
  common_name = var.ca_cn
  # Set Verbatim End Date instead of 'ttl'
  # not_after            = "2027-01-23T18:46:42Z"
  not_after            = var.ca_expiration
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  # ou                   = "My OU"
  organization = var.ca_organization
}


resource "vault_pki_secret_backend_role" "this" {
  for_each = local.policies_map

  backend    = vault_mount.this.path
  name       = each.value["role_name"]
  issuer_ref = vault_pki_secret_backend_root_cert.this.issuer_id

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
