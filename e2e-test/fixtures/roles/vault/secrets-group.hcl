# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0

# ${policy_name}
path "${secret_engines.kv.path}/data/groups/${split(".", access)[2]}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "${secret_engines.kv.path}/metadata/groups/${split(".", access)[2]}/*" {
  capabilities = ["read", "delete", "list"]
}
