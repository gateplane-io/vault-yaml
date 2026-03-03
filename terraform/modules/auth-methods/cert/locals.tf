# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

locals {
  # Parse Principal strings affecting this Auth Method
  # The 'principal_key' (default: 'cert') is used as prefix for Principals
  # in 'cert' entries, "cert.<common_name>",
  # e.g: cert.example.com
  authorizations = {
    "common_names" = {
      for access in distinct([
        # Only get 'cert' accesses
        for el in var.policies_list[*]["access"] : el
        if split(".", el)[0] == var.principal_key
      ]) :
      # Get all the rest after the "<principal_key>."
      replace(access, "/^${var.principal_key}\\./", "") => {
        "policies" : [
          for v in var.policies_list : v["key"]
          if access == v["access"]
        ]
      }
    }
  }
}
