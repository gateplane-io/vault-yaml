# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0

# ${policy_name}
path "${secret_engines.kv.path}/data/users/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "${secret_engines.kv.path}/metadata/users/{{identity.entity.name}}/*" {
  capabilities = ["read", "delete", "list"]
}
