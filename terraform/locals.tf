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
  accesses = yamldecode(file("${path.module}/../access.example.yaml"))

  # Defined to be used when templating
  # 'adhoc' Vault Policies
  auth_methods = {
    "ldap" : module.ldap.entry,
    # ... extend here
  }
  #
  secret_engines = {
    "kv" : {
      "accessor" : vault_mount.kvv2.accessor,
      "path" : vault_mount.kvv2.path,
    },
    # Module outputs should be added:
    (module.ca.entry["accessor"])         = module.ca.entry,
    (module.kubernetes.entry["accessor"]) = module.kubernetes.entry,
    # ... extend here
  }


  # === Resource ---> Auth reverse mapping ===
  policies_list = flatten([
    module.adhoc.access_list,
    module.ca.access_list,
    module.kubernetes.access_list,
    # ... extend here
  ])

  # The 'key' ('ldap') is used as prefix for accesses.yaml
  # 'access' entries,
  # e.g: ldap.users.someuser or ldap.groups.Everyone
  # TODO: move this in LDAP module
  authorization = {
    "ldap" = {
      "groups" = {
        for access in distinct([
          # Only get LDAP accesses
          for el in local.policies_list[*]["access"] : el
          if split(".", el)[0] == "ldap" && split(".", el)[1] == "groups"
        ]) :
        split(".", access)[2] => {
          "policies" : [
            for v in local.policies_list : v["key"]
            if access == v["access"]
          ]
        }
      },
      "users" = {
        for access in distinct([
          # Only get LDAP accesses
          for el in local.policies_list[*]["access"] : el
          if split(".", el)[0] == "ldap" && split(".", el)[1] == "users"
        ]) :
        split(".", access)[2] => {
          "policies" : [
            for v in local.policies_list : v["key"]
            if access == v["access"]
          ]
        }
      }
    }
  }
}
