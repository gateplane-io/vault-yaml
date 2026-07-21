# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0

# ${policy_name}
path "${secret_engines.kv.path}/data/shared" {
  capabilities = ["read"]
}
