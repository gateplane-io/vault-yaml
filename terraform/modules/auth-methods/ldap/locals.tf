# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

locals {
  # Parse Principal strings affecting this Auth Method
  # The 'principal_key' (default: 'ldap') is used as prefix for Principals
  # in 'access' entries,
  # e.g: ldap.users.someuser or ldap.groups.Everyone
  authorizations = {
    "groups" = {
      for access in distinct([
        # Only get LDAP accesses
        for el in var.policies_list[*]["access"] : el
        if split(".", el)[0] == var.principal_key && split(".", el)[1] == "groups"
      ]) :
      split(".", access)[2] => {
        "policies" : [
          for v in var.policies_list : v["key"]
          if access == v["access"]
        ]
      }
    },
    "users" = {
      for access in distinct([
        # Only get LDAP accesses
        for el in var.policies_list[*]["access"] : el
        if split(".", el)[0] == var.principal_key && split(".", el)[1] == "users"
      ]) :
      split(".", access)[2] => {
        "policies" : [
          for v in var.policies_list : v["key"]
          if access == v["access"]
        ]
      }
    }
  }
}
