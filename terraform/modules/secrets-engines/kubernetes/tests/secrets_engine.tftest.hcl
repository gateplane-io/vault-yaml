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

run "role_mapping_policy_and_custom_options" {
  command = plan

  variables {
    mount = {
      path     = "clusters/production"
      accessor = "kubernetes_mock"
    }
    role_directory           = "tests/fixtures/roles"
    name_prefix              = "platform"
    enable_conditional_roles = false
    name_template            = "{{.RoleName}}-{{unix_time}}"
    kubernetes_labels = {
      managed_by = "terraform-test"
      team       = "platform"
    }
    accesses = {
      "clusters/production" = {
        type = "kubernetes"
        roles = {
          admin = {
            namespaces = ["*"]
            ttl        = 900
            ttl_max    = 7200
            access = {
              static      = ["ldap.groups.Administrators"]
              conditional = {}
            }
          }
          deployer = {
            namespaces = ["apps", "staging"]
            access = {
              static      = ["ldap.groups.Developers"]
              conditional = {}
            }
          }
        }
      }
      "clusters/ignored" = {
        type  = "kubernetes"
        roles = {}
      }
    }
  }

  assert {
    condition     = vault_kubernetes_secret_backend_role.this["platform-kubernetes-admin-production"].generated_role_rules == file("tests/fixtures/roles/admin.yaml")
    error_message = "The parsed admin role must map to its YAML role definition."
  }

  assert {
    condition     = vault_kubernetes_secret_backend_role.this["platform-kubernetes-admin-production"].kubernetes_role_type == "ClusterRole" && vault_kubernetes_secret_backend_role.this["platform-kubernetes-deployer-production"].kubernetes_role_type == "Role"
    error_message = "Wildcard namespaces must create ClusterRoles while scoped namespaces create Roles."
  }

  assert {
    condition     = vault_kubernetes_secret_backend_role.this["platform-kubernetes-deployer-production"].token_default_ttl == 600 && vault_kubernetes_secret_backend_role.this["platform-kubernetes-deployer-production"].token_max_ttl == 3600
    error_message = "Kubernetes parser defaults must reach the backend role."
  }

  assert {
    condition = (
      vault_kubernetes_secret_backend_role.this["platform-kubernetes-admin-production"].extra_labels["managed_by"] == "terraform-test" &&
      vault_kubernetes_secret_backend_role.this["platform-kubernetes-admin-production"].extra_labels["team"] == "platform" &&
      vault_kubernetes_secret_backend_role.this["platform-kubernetes-admin-production"].extra_labels["provisioned_for"] == "platform" &&
      vault_kubernetes_secret_backend_role.this["platform-kubernetes-admin-production"].extra_labels["generated_from"] == "clusters/production/admin"
    )
    error_message = "Custom labels and generated provenance labels must be merged."
  }

  assert {
    condition     = vault_kubernetes_secret_backend_role.this["platform-kubernetes-admin-production"].name_template == "platform-{{.RoleName}}-{{unix_time}}"
    error_message = "The name prefix must be applied to a custom service-account name template."
  }

  assert {
    condition     = data.vault_policy_document.this["platform-kubernetes-deployer-production"].rule[0].path == "clusters/production/creds/deployer" && tolist(data.vault_policy_document.this["platform-kubernetes-deployer-production"].rule[0].allowed_parameter[0].value) == tolist(["apps", "staging"])
    error_message = "The policy must target the mapped role and constrain requested namespaces."
  }

  assert {
    condition     = output.entry == { path = "clusters/production", accessor = "kubernetes_mock" } && length(output.access_list) == 2
    error_message = "Outputs must retain mount metadata and parsed static accesses."
  }
}
