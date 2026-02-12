# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_ldap_auth_backend_group" "groups" {
  for_each  = local.authorizations["groups"]
  groupname = each.key
  policies  = flatten([[], [for p in each.value["policies"] : lower(p)]])
  backend   = var.mount.path
}

resource "vault_ldap_auth_backend_user" "ldap" {
  for_each = local.authorizations["users"]
  username = each.key
  policies = [for p in each.value["policies"] : lower(p)]
  backend  = var.mount.path
}
