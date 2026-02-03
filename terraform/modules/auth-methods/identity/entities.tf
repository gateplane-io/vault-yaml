# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_identity_entity_policies" "this" {
  for_each = local.authorizations["entity_ids"]
  policies = each.value["policies"]

  exclusive = var.exclusive

  entity_id = each.key
}

data "vault_identity_entity" "this" {
  for_each = local.authorizations["entity_names"]

  entity_name = each.key
}

resource "vault_identity_entity_policies" "this_names" {
  for_each = local.authorizations["entity_names"]
  policies = each.value["policies"]

  exclusive = var.exclusive

  entity_id = data.vault_identity_entity.this[each.key].id
}
