# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_kubernetes_secret_backend_role" "this" {
  for_each = local.all_policies

  backend                       = var.mount.path
  name                          = each.value["role_name"]
  allowed_kubernetes_namespaces = sort(each.value["namespaces"])

  token_max_ttl     = each.value["ttl_max"]
  token_default_ttl = each.value["ttl"]

  kubernetes_role_type = contains(each.value["namespaces"], "*") ? "ClusterRole" : "Role"

  generated_role_rules = local.role_definitions[each.value["role_name"]]

  extra_labels = merge({
    # role_definition = "${var.repository_url}/blob/${local.git_commit_sha}/${var.roles_directory}/kubernetes/${each.value["role_name"]}.yaml",
    provisioned_for = var.name_prefix,
    generated_from  = "${var.mount.path}/${each.value["role_name"]}"
    },
    var.kubernetes_labels
  )

  name_template = local.name_template
}
