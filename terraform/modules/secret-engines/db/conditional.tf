
module "gateplane" {
  source = "../../../modules/conditional-access"

  accesses = local.pgsql

  name_prefix = var.name_prefix

  policies = vault_policy.pgsql
}
