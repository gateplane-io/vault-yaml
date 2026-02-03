# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "kubernetes_host" {}

variable "description" {}

variable "path" {}

variable "enable_conditional_roles" {
  default = true
}

variable "service_account_jwt" {
  sensitive = true
}

variable "kubernetes_ca_cert" {}

variable "name_template" {
  default = "{{.DisplayName | replace \"_\" \"-\"  | replace \" \" \"\"}}-{{.RoleName | replace \"_\" \"-\"}}-{{unix_time}}s"
}

# ======

variable "role_directory" {
  type = string
}

variable "accesses" {

}

variable "name_prefix" {
  default = ""
}

variable "kubernetes_labels" {
  default = {
    managed_by = "vault"
  }
}
