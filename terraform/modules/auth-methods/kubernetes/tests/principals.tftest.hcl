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

run "kubernetes_principal" {
  command = plan

  variables {
    mount = {
      path     = "kubernetes"
      accessor = "auth_kubernetes_mock"
    }
    policies_list = [
      {
        key    = "EXTERNAL-SECRETS-READ"
        access = "kubernetes.default.external-secrets"
      },
      {
        key    = "EXTERNAL-SECRETS-WRITE"
        access = "kubernetes.default.external-secrets"
      },
      {
        key    = "IGNORED"
        access = "ldap.users.external-secrets"
      }
    ]
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.this["default.external-secrets"].role_name == "default-external-secrets"
    error_message = "The principal must produce a stable Kubernetes role name."
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.this["default.external-secrets"].bound_service_account_names == toset(["external-secrets"])
    error_message = "The principal must bind the requested ServiceAccount."
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.this["default.external-secrets"].bound_service_account_namespaces == toset(["default"])
    error_message = "The principal must bind the requested namespace."
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.this["default.external-secrets"].token_policies == toset(["external-secrets-read", "external-secrets-write"])
    error_message = "All matching policies must be normalized and attached to the role."
  }

  assert {
    condition     = length(output.authorizations["kubernetes"]) == 1
    error_message = "Unrelated auth-method principals must be ignored."
  }
}

run "multiple_serviceaccounts" {
  command = plan

  variables {
    mount = {
      path     = "kubernetes"
      accessor = "auth_kubernetes_mock"
    }
    policies_list = [
      {
        key    = "WORKLOAD-A"
        access = "kubernetes.namespace-a.serviceaccount-a"
      },
      {
        key    = "WORKLOAD-B"
        access = "kubernetes.namespace-b.serviceaccount-b"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["kubernetes"]) == 2
    error_message = "Each namespace and ServiceAccount pair must create an authorization."
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.this["namespace-a.serviceaccount-a"].bound_service_account_namespaces == toset(["namespace-a"])
    error_message = "The first authorization must retain its namespace."
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.this["namespace-b.serviceaccount-b"].bound_service_account_names == toset(["serviceaccount-b"])
    error_message = "The second authorization must retain its ServiceAccount."
  }
}

run "custom_principal_key_and_options" {
  command = plan

  variables {
    mount = {
      path     = "kubernetes/cluster-a"
      accessor = "auth_kubernetes_cluster_a"
    }
    principal_key = "cluster-a"
    policies_list = [
      {
        key    = "CERT-MANAGER"
        access = "cluster-a.security.cert-manager::token_ttl=900,audience=vault"
      },
      {
        key    = "IGNORED-DEFAULT-KEY"
        access = "kubernetes.default.ignored"
      }
    ]
  }

  assert {
    condition     = tonumber(output.authorizations["cluster-a"]["security.cert-manager"].token_ttl) == 900
    error_message = "Principal numeric options must remain usable as numbers."
  }

  assert {
    condition     = output.authorizations["cluster-a"]["security.cert-manager"].audience == "vault"
    error_message = "Principal options must preserve string values."
  }

  assert {
    condition     = length(output.authorizations["cluster-a"]) == 1
    error_message = "A custom principal_key must ignore principals using another key."
  }

  assert {
    condition     = vault_kubernetes_auth_backend_role.this["security.cert-manager"].role_name == "security-cert-manager"
    error_message = "Custom principal keys must still create the expected role."
  }
}
