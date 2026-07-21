# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_kubernetes_auth_backend_role" "this" {
  for_each = local.authorizations

  backend = var.mount.path

  role_name = replace(each.key, ".", "-")

  bound_service_account_names      = [each.value["service_account"]]
  bound_service_account_namespaces = [each.value["namespace"]]

  token_policies = [for p in each.value["policies"] : lower(p)]

  # token_ttl = 3600
  # audience  = "vault"
}
