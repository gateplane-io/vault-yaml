# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

/*
  ====================================================
  This file IS PART OF the 'vault-yaml' installation

  Set the required version of GatePlane Policy Gate plugin,
  available in your Vault/OpenBao installation,
  or omit entirely to disable conditional access
  (`access.conditional` blocks in accesses.yaml).
  ====================================================
*/

locals {
  // Change in case of GatePlane Enterprise
  gateplane_webui_domain = "app.gateplane.io"

  // The Host:Port where Vault/OpenBao instance is reachable
  instance_hostport = "localhost:8200"
}

module "setup" {
  source  = "gateplane-io/setup/gateplane"
  version = "0.4.0"

  # https://github.com/gateplane-io/vault-plugins/releases
  policy_gate_plugin = {
    filename       = "gateplane-policy-gate"
    version        = "v1.0.1-base.0.3.2"
    sha256         = "55b4bdf9a89bc7297b056fc68dd2be8f0a8a2654cdf562134c380b25b4c0c04b"
    approle_policy = "gateplane-policy-gate-policy"
  }

  // Omit or explicitly add all origins to allow CORS from GatePlane WebUI
  url_origins = [
    "https://${local.gateplane_webui_domain}",
    "https://${local.instance_hostport}:8200"
  ]
}

/*
  ====================================================
  Consult module's documentation to enable GatePlane Services Subscription:
  https://github.com/gateplane-io/terraform-gateplane-services-setup?tab=readme-ov-file#how-to-enable-gateplane-services
  ====================================================
*/
module "gateplane_services" {
  source  = "gateplane-io/services-setup/gateplane"
  version = "0.1.2"

  // replace this with the location of the Vault/OpenBao instance
  issuer_host = local.instance_hostport

  // The Vault/OpenBao Entity metadata field where the SlackID of each user resides
  # messenger_entity_metadata = ["slack_id"]

  gateplane_webui_domain = local.gateplane_webui_domain

  /*
  # You can explicitly set which users take up the license seats,
  # or omit to allow everyone in Vault/OpenBao to connect
  allowed_entities = [
    # Vault/OpenBao Entity IDs:
    "c15cfc49-ecb1-4771-9b86-3139d8f37223",
    "0b9faf28-e043-45ef-8cc3-9ad83123af20",
    # ...
  ]
  */

}

/*
# Uncomment to show GatePlane Services information in output (non-sensitive values)
output "gateplane_services_output" {
  description = "Provide this output to GatePlane (net/no-net) and GatePlane UI users (webui)"
  value       = module.gateplane_services.full_output
}
*/
