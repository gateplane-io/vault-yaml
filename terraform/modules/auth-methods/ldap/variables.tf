# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "description" {
  type    = string
  default = "LDAP authentication method"
}

variable "path" {
  default = "ldap"
}

variable "authorizations" {
}


# ================
#
variable "ldap_url" {
  description = "The LDAP server URL"
  type        = string
}

variable "ldap_userdn" {
  description = "The base DN for user searches"
  type        = string
}

variable "ldap_userattr" {
  description = "The attribute on user entries matching the username"
  type        = string
  default     = "uid"
}

variable "ldap_groupdn" {
  description = "The base DN for group searches"
  type        = string
}

variable "ldap_groupfilter" {
  description = "The LDAP search filter to find groups for a user"
  type        = string
  default     = "(&(objectClass=person)(uid={{.Username}}))"
}

variable "ldap_groupattr" {
  description = "The attribute on group entries that contains group members"
  type        = string
  default     = "memberOf"
}

variable "ldap_discoverdn" {
  description = "Whether to discover user's DN"
  type        = bool
  default     = true
}

variable "ldap_username_as_alias" {
  description = "Whether to use username as alias"
  type        = bool
  default     = true
}

variable "ldap_case_sensitive_names" {
  description = "Whether usernames and group names are case sensitive"
  type        = bool
  default     = false
}

variable "ldap_deny_null_bind" {
  description = "Whether to deny null binds"
  type        = bool
  default     = true
}
