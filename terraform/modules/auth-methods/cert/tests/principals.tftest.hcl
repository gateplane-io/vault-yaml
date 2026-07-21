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
mock_provider "dns" {}

run "certificate_principals" {
  command = plan

  variables {
    mount = {
      path     = "cert"
      accessor = "auth_cert_mock"
    }
    trusted_certificate = "-----BEGIN CERTIFICATE-----\nmock\n-----END CERTIFICATE-----"
    policies_list = [
      {
        key    = "APP-READ"
        access = "cert.app.example.com::ip_bind=false"
      },
      {
        key    = "APP-WRITE"
        access = "cert.app.example.com::ip_bind=false"
      },
      {
        key    = "IGNORED"
        access = "ldap.users.app"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["cert"]["common_names"]) == 1
    error_message = "Unrelated principals must be ignored and duplicate certificate principals aggregated."
  }

  assert {
    condition     = output.authorizations["cert"]["common_names"]["app.example.com"].ip_bind == false
    error_message = "Certificate principal options must be retained in the parsed authorization."
  }

  assert {
    condition     = vault_cert_auth_backend_role.cert["app.example.com"].name == "app.example.com" && vault_cert_auth_backend_role.cert["app.example.com"].allowed_names == toset(["app.example.com"])
    error_message = "The certificate principal must create a role for its common name."
  }

  assert {
    condition     = vault_cert_auth_backend_role.cert["app.example.com"].token_policies == toset(["app-read", "app-write"])
    error_message = "All matching policies must be normalized and attached to the certificate role."
  }
}

run "custom_principal_key" {
  command = plan

  variables {
    mount = {
      path     = "cert/partners"
      accessor = "auth_cert_partners_mock"
    }
    principal_key       = "partner-cert"
    trusted_certificate = "-----BEGIN CERTIFICATE-----\nmock\n-----END CERTIFICATE-----"
    policies_list = [
      {
        key    = "PARTNER-READ"
        access = "partner-cert.partner@example.com"
      },
      {
        key    = "IGNORED-DEFAULT"
        access = "cert.default.example.com"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["partner-cert"]["common_names"]) == 1
    error_message = "A custom principal key must select only matching certificate principals."
  }

  assert {
    condition     = vault_cert_auth_backend_role.cert["partner@example.com"].name == "partner-example.com" && vault_cert_auth_backend_role.cert["partner@example.com"].backend == "cert/partners"
    error_message = "Custom certificate principals must create a stable role on the requested mount."
  }
}
