# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "mount" {
  description = "The mount configuration object for the Kubernetes secrets engine ([`vault_kubernetes_secret_backend`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_secret_backend))."
}

variable "enable_conditional_roles" {
  description = "Enable or disable conditional access roles that require approval workflows."
  default     = true
}

variable "name_template" {
  description = "Template for generating Kubernetes Service Account names."
  default     = "{{.DisplayName | replace \"_\" \"-\"  | replace \" \" \"\"}}-{{.RoleName | replace \"_\" \"-\"}}-{{unix_time}}s"
}

# ======

variable "role_directory" {
  description = "The directory path containing Kubernetes role definition YAML files."
  type        = string
}

variable "accesses" {
  description = "Map of access configurations for Kubernetes secrets engine, defining roles and their properties."
}

variable "name_prefix" {
  description = "Prefix to prepend to resource names created by this module."
  default     = ""
}

variable "kubernetes_labels" {
  default = {
    managed_by = "vault"
  }
}
