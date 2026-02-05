# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

module "setup" {
  source  = "gateplane-io/setup/gateplane"
  version = "0.4.0"

  # https://github.com/gateplane-io/vault-plugins/releases
  policy_gate_plugin = {
    filename       = "gateplane-policy-gate"
    version        = "v1.0.0-base.0.3.1"
    sha256         = "926a2f812fbbc26513422043c75f78816332d1b7d6ab3c36e0bbc03d944eff0a"
    approle_policy = "gateplane-policy-gate-policy"
  }

  url_origins = [
    "https://app.gateplane.io",
    "https://localhost:8200" // Add instance FQDN
  ]
}
