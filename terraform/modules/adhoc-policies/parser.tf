module "parser" {
  source = "../role-parser"

  name_prefix = var.name_prefix

  accesses = var.accesses
  path     = "adhoc"

  field_defaults = {
    "for_each" : false,
  }
}
