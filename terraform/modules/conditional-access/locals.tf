locals {
  name_prefix = var.name_prefix == "" ? "" : "${var.name_prefix}-"

  # Keep the data relevant for Vault Policies (remove accesses)
  conditional_roles = {
    for k in distinct(var.roles_conditional) :
    k["key"] => k
    if try(k["access_conditional"] != {}, false)
  }
}
