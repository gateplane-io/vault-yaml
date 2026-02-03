# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_ldap_auth_backend" "this" {
  description = var.description

  path = var.path
  url  = var.ldap_url

  userdn   = var.ldap_userdn
  userattr = var.ldap_userattr

  # Use the query and search their 'memberOf' field values
  groupdn     = var.ldap_groupdn
  groupfilter = var.ldap_groupfilter
  groupattr   = var.ldap_groupattr

  discoverdn           = var.ldap_discoverdn
  username_as_alias    = var.ldap_username_as_alias
  case_sensitive_names = var.ldap_case_sensitive_names
  deny_null_bind       = var.ldap_deny_null_bind
}

resource "vault_ldap_auth_backend_group" "groups" {
  for_each  = local.authorizations["groups"]
  groupname = each.key
  policies  = flatten([[], [for p in each.value["policies"] : lower(p)]])
  backend   = vault_ldap_auth_backend.this.path
}

resource "vault_ldap_auth_backend_user" "ldap" {
  for_each = local.authorizations["users"]
  username = each.key
  policies = [for p in each.value["policies"] : lower(p)]
  backend  = vault_ldap_auth_backend.this.path
}
