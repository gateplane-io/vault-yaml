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
  authorizations = {
    "entity_names" = {
      for access in distinct([
        # Only get LDAP accesses
        for el in var.policies_list[*]["access"] : el
        if split(".", el)[0] == var.principal_key && split(".", el)[1] == "entity_name"
      ]) :
      split(".", access)[2] => {
        "policies" : [
          for v in var.policies_list : v["key"]
          if access == v["access"]
        ]
      }
    },
    "entity_ids" = {
      for access in distinct([
        # Only get LDAP accesses
        for el in var.policies_list[*]["access"] : el
        if split(".", el)[0] == var.principal_key && split(".", el)[1] == "entity_id"
      ]) :
      split(".", access)[2] => {
        "policies" : [
          for v in var.policies_list : v["key"]
          if access == v["access"]
        ]
      }
    },
    "group_ids" = {
      for access in distinct([
        # Only get LDAP accesses
        for el in var.policies_list[*]["access"] : el
        if split(".", el)[0] == var.principal_key && split(".", el)[1] == "group_id"
      ]) :
      split(".", access)[2] => {
        "policies" : [
          for v in var.policies_list : v["key"]
          if access == v["access"]
        ]
      }
    },
    "group_names" = {
      for access in distinct([
        # Only get LDAP accesses
        for el in var.policies_list[*]["access"] : el
        if split(".", el)[0] == var.principal_key && split(".", el)[1] == "group_name"
      ]) :
      split(".", access)[2] => {
        "policies" : [
          for v in var.policies_list : v["key"]
          if access == v["access"]
        ]
      }
    },
  }
}
