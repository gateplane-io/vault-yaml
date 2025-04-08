# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

output "accessor" {
  value = vault_ldap_auth_backend.this.accessor
}

output "path" {
  value = vault_ldap_auth_backend.this.path
}

output "entry" {
  value = {
    "accessor" : vault_ldap_auth_backend.this.accessor,
    "path" : vault_ldap_auth_backend.this.path,
  }
}
