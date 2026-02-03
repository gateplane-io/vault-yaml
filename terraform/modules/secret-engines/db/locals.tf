locals {
  name_prefix   = var.name_prefix == "" ? "" : "${var.name_prefix}-"
  name_template = var.name_prefix == "" ? var.name_template : "${var.name_prefix}-${var.name_template}"

  pgsql = {
    for path, accesses_values in var.accesses :
    path => accesses_values if accesses_values["type"] == "pgsql"
  }

  # Inverse the access to "auth -> secrets"
  pgsql_policies_list = flatten([
    for path, values in local.pgsql : [
      for role_name, role in values["roles"] : [
        for access in role["access"] : {
          "path" : path,
          "role_name" : role_name,
          "databases" : try(role["databases"], ["postgres"])
          "key" : "${local.name_prefix}${values["type"]}-${role_name}-${element(split("/", path), -1)}",
          "resource_name" : element(split("/", path), -1),
          "access" : access,
          "ttl" : try(role["ttl"], 10 * 60),
          "ttl_max" : try(role["ttl_max"], 60 * 60),
        }
      ]
    ]
  ])

  # Keep the data relevant for Vault Policies (remove accesses)
  pgsql_policies = {
    for k in distinct([
      for l in local.pgsql_policies_list : merge([l, { "access" = null }]...)
    ]) : k["key"] => k
  }

}