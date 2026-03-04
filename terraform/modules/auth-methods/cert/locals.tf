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
    common_names = {
      for access in distinct([
        for el in var.policies_list[*]["access"] : el
        if split(".", split("::", el)[0])[0] == var.principal_key
      ]) :

      # Extract domain (after "<principal_key>.")
      replace(split("::", access)[0], "/^${var.principal_key}\\./", "") => merge(

        # Existing policies block
        {
          policies = [
            for v in var.policies_list : v["key"]
            if access == v["access"]
          ]
        },

        # Optional "::key=value,key2=value2" parsing
        length(split("::", access)) > 1 ? {
          for pair in split(",", split("::", access)[1]) :
          split("=", pair)[0] => (
            split("=", pair)[1] == "true" ? true :
            split("=", pair)[1] == "false" ? false :
            try(tonumber(split("=", pair)[1]), split("=", pair)[1])
          )
        } : {}
      )
    }
  }
}
