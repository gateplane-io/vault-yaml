# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

/*
  ====================================================
  Resources defined in this file are example "pre-existing"
  configuration to be managed by 'vault-yaml'.

  They are not considered part of 'vault-yaml' installation.
  ====================================================
*/
resource "vault_ldap_auth_backend" "this" {
  description = "Org LDAP Auth Method"

  path = "ldap"
  url  = "ldaps://ldap.example.com"

  userdn   = "dc=org,dc=com"
  userattr = "uid"

  # Use the query and search their 'memberOf' field values
  groupdn     = "dc=org,dc=com"
  groupfilter = "(&(objectClass=person)(uid={{.Username}}))"
  groupattr   = "memberOf"

}
