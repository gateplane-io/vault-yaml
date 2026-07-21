# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

mock_provider "vault" {
  mock_data "vault_identity_entity" {
    defaults = {
      id = "entity-from-name-id"
    }
  }

  mock_data "vault_identity_group" {
    defaults = {
      id = "group-from-name-id"
    }
  }
}

run "identity_principal_types" {
  command = plan

  variables {
    exclusive = true
    policies_list = [
      {
        key    = "ENTITY-READ"
        access = "identity.entity_id.entity-123"
      },
      {
        key    = "ENTITY-WRITE"
        access = "identity.entity_name.alice"
      },
      {
        key    = "GROUP-READ"
        access = "identity.group_id.group-123"
      },
      {
        key    = "GROUP-WRITE"
        access = "identity.group_name.engineering"
      },
      {
        key    = "IGNORED"
        access = "ldap.users.alice"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["identity"]["entity_ids"]) == 1 && length(output.authorizations["identity"]["entity_names"]) == 1 && length(output.authorizations["identity"]["group_ids"]) == 1 && length(output.authorizations["identity"]["group_names"]) == 1
    error_message = "Every supported identity principal type must be parsed and unrelated principals ignored."
  }

  assert {
    condition     = vault_identity_entity_policies.this["entity-123"].entity_id == "entity-123" && vault_identity_entity_policies.this["entity-123"].policies == toset(["ENTITY-READ"]) && vault_identity_entity_policies.this["entity-123"].exclusive
    error_message = "Entity IDs must receive their matching policies and exclusive setting."
  }

  assert {
    condition     = vault_identity_entity_policies.this_names["alice"].entity_id == "entity-from-name-id" && vault_identity_entity_policies.this_names["alice"].policies == toset(["ENTITY-WRITE"])
    error_message = "Entity names must resolve to IDs and receive their matching policies."
  }

  assert {
    condition     = vault_identity_group_policies.this["group-123"].group_id == "group-123" && vault_identity_group_policies.this["group-123"].policies == toset(["GROUP-READ"])
    error_message = "Group IDs must receive their matching policies."
  }

  assert {
    condition     = vault_identity_group_policies.this_names["engineering"].group_id == "group-from-name-id" && vault_identity_group_policies.this_names["engineering"].policies == toset(["GROUP-WRITE"])
    error_message = "Group names must resolve to IDs and receive their matching policies."
  }
}

run "custom_principal_key" {
  command = plan

  variables {
    principal_key = "corporate-identity"
    policies_list = [
      {
        key    = "CUSTOM-READ"
        access = "corporate-identity.entity_id.entity-456"
      },
      {
        key    = "IGNORED-DEFAULT"
        access = "identity.entity_id.entity-ignored"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["corporate-identity"]["entity_ids"]) == 1 && output.authorizations["corporate-identity"]["entity_ids"]["entity-456"].policies == ["CUSTOM-READ"]
    error_message = "A custom identity principal key must select and parse only matching principals."
  }

  assert {
    condition     = vault_identity_entity_policies.this["entity-456"].entity_id == "entity-456"
    error_message = "A custom identity principal must create the expected policy assignment."
  }
}
