module "parser" {
  source = "../../role-parser"

  name_prefix = var.name_prefix

  accesses = var.accesses
  path     = var.path

  field_defaults = {
    "ttl" : 60
    "ttl_max" : 10 * 60,

    "extensions" : ["permit-pty"]
  }
}
