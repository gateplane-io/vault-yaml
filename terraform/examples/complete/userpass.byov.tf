# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

module "userpass" {
  source = "github.com/gateplane-io/terraform-test-modules//tokens?ref=1.1.0"

  entity_groups = {
    "test" = {
      quantity = 3
      policies = []
    }
  }

  vault_api_url = "http://${local.instance_hostport}/v1"
}

# module "userpass-yaml" {
#   source = "./modules/auth-methods/userpass"

#   mount = module.userpass.mount

#   policies_list = local.policies_list
#   # handles Principals starting with 'ldap'
#   # (e.g: ldap.users.jdoe)
#   principal_key = "userpass"
# }

# output "userpass" {
#   value = module.userpass.token_map
# }
