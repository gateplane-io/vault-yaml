# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

#
resource "vault_generic_endpoint" "userpass_user" {
  for_each = local.authorizations["users"]

  path = "auth/${var.mount.path}/users/${each.key}/policies"
  data_json = jsonencode({
    token_policies = [for p in each.value["policies"] : lower(p)]
  })

  ignore_absent_fields = true
  disable_read         = true
  disable_delete       = true
}
