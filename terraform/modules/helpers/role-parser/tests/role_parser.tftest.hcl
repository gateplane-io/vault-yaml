# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

run "parse_static_and_conditional_roles" {
  command = plan

  variables {
    path        = "secret/data/application"
    name_prefix = "example"
    field_defaults = {
      ttl      = "1h"
      audience = "default-audience"
    }
    accesses = {
      "secret/data/application" = {
        type = "kv"
        roles = {
          reader = {
            ttl = "30m"
            access = {
              static      = ["group.reader"]
              conditional = {}
            }
          }
          operator = {
            audience = "operators"
            access = {
              static = []
              conditional = {
                requestors            = ["group.requestors"]
                approvers             = ["group.approvers"]
                required_approvals    = 2
                require_justification = true
                description           = "Temporary operator access"
              }
            }
          }
        }
      }
      "secret/data/ignored" = {
        type = "kv"
        roles = {
          ignored = {
            access = {
              static      = ["group.ignored"]
              conditional = {}
            }
          }
        }
      }
    }
  }

  assert {
    condition     = length(output.roles_list_static) == 1 && output.roles_list_static[0].key == "example-kv-reader-application"
    error_message = "Only static roles from the selected path should be parsed with the configured prefix."
  }

  assert {
    condition     = output.roles_list_static[0].ttl == "30m" && output.roles_list_static[0].audience == "default-audience"
    error_message = "Explicit role fields should override defaults while missing fields inherit defaults."
  }

  assert {
    condition     = length(output.roles_list_conditional) == 1 && output.roles_list_conditional[0].access_conditional.required_approvals == 2 && output.roles_list_conditional[0].access_conditional.require_justification
    error_message = "Conditional approval settings should be retained."
  }

  assert {
    condition     = output.roles_list_conditional[0].ttl == "1h" && output.roles_list_conditional[0].audience == "operators"
    error_message = "Field defaults and role overrides should also apply to conditional roles."
  }

  assert {
    condition     = length(output.roles_list) == 2 && length(output.policies_map) == 2
    error_message = "The combined role list and policy map should contain both selected roles."
  }

  assert {
    condition     = output.policies_map["example-kv-reader-application"].access == null && output.policies_map["example-kv-operator-application"].access_conditional == null
    error_message = "Policy records should omit access-specific data."
  }
}

run "expand_for_each_static_access_and_use_conditional_defaults" {
  command = plan

  variables {
    path = "database/postgres"
    accesses = {
      "database/postgres" = {
        type = "database"
        roles = {
          app = {
            for_each = true
            access = {
              static = [
                "identity.entity.alpha",
                "identity.entity.beta",
              ]
              conditional = {
                requestors = ["group.requestors"]
                approvers  = ["group.approvers"]
              }
            }
          }
        }
      }
    }
  }

  assert {
    condition     = toset([for role in output.roles_list_static : role.key]) == toset(["database-app-postgres-alpha", "database-app-postgres-beta"])
    error_message = "for_each roles should include the access identity in each generated static key."
  }

  assert {
    condition     = output.roles_list_conditional[0].key == "database-app-postgres" && output.roles_list_conditional[0].access_conditional.required_approvals == 1 && !output.roles_list_conditional[0].access_conditional.require_justification && output.roles_list_conditional[0].access_conditional.description == ""
    error_message = "Conditional roles should use the documented approval defaults."
  }
}
