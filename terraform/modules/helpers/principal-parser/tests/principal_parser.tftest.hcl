# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

run "parse_and_aggregate_principals" {
  command = plan

  variables {
    principal_key = "kubernetes"
    policies_list = [
      {
        key    = "READ"
        access = "kubernetes.default.external-secrets::token_ttl=900,audience=vault"
      },
      {
        key    = "WRITE"
        access = "kubernetes.default.external-secrets::token_ttl=900,audience=vault"
      },
      {
        key    = "DOT-NAME"
        access = "kubernetes.platform.operator.service.account"
      },
      {
        key    = "IGNORED"
        access = "kubernetes-other.default.ignored"
      }
    ]
  }

  assert {
    condition     = length(output.principals) == 2
    error_message = "Only principals matching the exact principal_key must be returned."
  }

  assert {
    condition     = output.principals["default.external-secrets"].policies == ["READ", "WRITE"]
    error_message = "Policies targeting the same access must be aggregated in input order."
  }

  assert {
    condition     = tolist(output.principals["default.external-secrets"].parts) == tolist(["default", "external-secrets"])
    error_message = "The parser must expose prefix-free principal segments."
  }

  assert {
    condition     = tonumber(output.principals["default.external-secrets"].token_ttl) == 900 && output.principals["default.external-secrets"].audience == "vault"
    error_message = "Optional principal settings must remain available to consumers."
  }

  assert {
    condition     = output.principals["platform.operator.service.account"].principal == "platform.operator.service.account" && length(output.principals["platform.operator.service.account"].parts) == 4
    error_message = "Dots in the principal body must be retained rather than truncated."
  }
}

run "custom_principal_key" {
  command = plan

  variables {
    principal_key = "corporate-ldap"
    policies_list = [
      {
        key    = "DEVELOPERS"
        access = "corporate-ldap.groups.Developers"
      },
      {
        key    = "IGNORED"
        access = "ldap.groups.Developers"
      }
    ]
  }

  assert {
    condition     = keys(output.principals) == ["groups.Developers"]
    error_message = "Custom principal keys must select only their own principals."
  }

  assert {
    condition     = output.principals["groups.Developers"].access == "corporate-ldap.groups.Developers"
    error_message = "The original access string must be retained for consumers and diagnostics."
  }
}
