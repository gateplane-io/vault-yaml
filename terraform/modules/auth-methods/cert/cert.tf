# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_cert_auth_backend_role" "cert" {
  for_each = local.authorizations["common_names"]

  name          = each.key
  certificate   = var.trusted_certificate
  backend       = var.mount.path
  allowed_names = [each.key]

  # More opinionated checks can be exposed here
  # like CRL, allowed SANS,etc

  token_policies = [for p in each.value["policies"] : lower(p)]
}
