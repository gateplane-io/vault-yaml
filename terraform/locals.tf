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
    (module.ldap.principal_key) : module.ldap.entry,
    # ... extend here
  }
  #
  secret_engines = {
    # Manually adding KV storage
    "kv" = {
      "accessor" : vault_mount.kvv2.accessor,
      "path" : vault_mount.kvv2.path,
    },
    # Module outputs should be added:
    (module.ca.entry["path"])         = module.ca.entry,
    (module.kubernetes.entry["path"]) = module.kubernetes.entry,
    (module.ssh.entry["path"])        = module.ssh.entry,
    # ... extend here
  }


  # === Resource ---> Auth reverse mapping ===
  # used by the Auth Methods
  policies_list = flatten([
    module.adhoc.access_list,
    module.ca.access_list,
    module.kubernetes.access_list,
    module.ssh.access_list,
    # ... extend here
  ])

  # Populates the output field
  authorizations = [
    module.ldap.authorizations,
  ]
}
