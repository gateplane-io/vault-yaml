# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0

# ${policy_name}
path "${secret_engines.kv.path}/data/${split(".", access)[2]}" {
  capabilities = ["read", "update"]
}

path "${auth_methods.ldap.path}/users/${split(".", access)[2]}" {
  capabilities = ["read"]
}
