# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_identity_group_policies" "this" {
  for_each = local.authorizations["group_ids"]
  policies = each.value["policies"]

  exclusive = var.exclusive

  group_id = each.key
}


data "vault_identity_group" "this" {
  for_each = local.authorizations["group_names"]

  group_name = each.key
}

resource "vault_identity_group_policies" "this_names" {
  for_each = local.authorizations["group_names"]
  policies = each.value["policies"]

  exclusive = var.exclusive

  group_id = data.vault_identity_group.this[each.key].id
}
