# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_identity_group" "ldap" {
  for_each = local.authorizations["groups"]

  name     = each.key
  type     = "external"
  policies = [] // Policies are assigned by the auth method only

  metadata = {
    version = "2"
  }
}

resource "vault_identity_group_alias" "ldap" {
  for_each = local.authorizations["groups"]

  name           = each.key
  mount_accessor = var.mount.accessor
  canonical_id   = vault_identity_group.ldap[each.key].id
}
