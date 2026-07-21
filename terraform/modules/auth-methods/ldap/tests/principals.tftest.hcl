# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

mock_provider "vault" {}

run "ldap_users_and_groups" {
  command = plan

  variables {
    mount = {
      path     = "ldap"
      accessor = "auth_ldap_mock"
    }
    policies_list = [
      {
        key    = "DEVELOPERS-READ"
        access = "ldap.groups.Developers"
      },
      {
        key    = "DEVELOPERS-WRITE"
        access = "ldap.groups.Developers"
      },
      {
        key    = "ALICE-READ"
        access = "ldap.users.alice"
      },
      {
        key    = "IGNORED"
        access = "userpass.alice"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["ldap"]["groups"]) == 1 && length(output.authorizations["ldap"]["users"]) == 1
    error_message = "LDAP users and groups must be parsed while unrelated principals are ignored."
  }

  assert {
    condition     = vault_ldap_auth_backend_group.groups["Developers"].groupname == "Developers" && vault_ldap_auth_backend_group.groups["Developers"].policies == toset(["developers-read", "developers-write"])
    error_message = "LDAP groups must aggregate and normalize all matching policies."
  }

  assert {
    condition     = vault_identity_group.ldap["Developers"].name == "Developers" && vault_identity_group.ldap["Developers"].type == "external" && vault_identity_group_alias.ldap["Developers"].mount_accessor == "auth_ldap_mock"
    error_message = "LDAP groups must create an external identity group and alias on the LDAP mount."
  }

  assert {
    condition     = vault_ldap_auth_backend_user.ldap["alice"].username == "alice" && vault_ldap_auth_backend_user.ldap["alice"].policies == toset(["alice-read"])
    error_message = "LDAP users must receive normalized matching policies."
  }
}

run "custom_principal_key" {
  command = plan

  variables {
    mount = {
      path     = "ldap/corporate"
      accessor = "auth_ldap_corporate_mock"
    }
    principal_key = "corporate-ldap"
    policies_list = [
      {
        key    = "OPS-READ"
        access = "corporate-ldap.groups.Operations"
      },
      {
        key    = "IGNORED-DEFAULT"
        access = "ldap.groups.Ignored"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["corporate-ldap"]["groups"]) == 1 && output.authorizations["corporate-ldap"]["groups"]["Operations"].policies == ["OPS-READ"]
    error_message = "A custom LDAP principal key must select only matching groups."
  }

  assert {
    condition     = vault_ldap_auth_backend_group.groups["Operations"].backend == "ldap/corporate" && vault_identity_group_alias.ldap["Operations"].mount_accessor == "auth_ldap_corporate_mock"
    error_message = "Custom LDAP principals must use the requested mount path and accessor."
  }
}
