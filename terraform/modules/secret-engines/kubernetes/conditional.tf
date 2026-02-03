
module "gateplane" {
  count  = var.enable_conditional_roles ? 1 : 0
  source = "../../../modules/conditional-access"

  name_prefix = var.name_prefix

  roles_conditional = local.roles_list
  policies          = vault_policy.this
}
