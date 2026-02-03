module "parser" {
  source = "../../role-parser"

  name_prefix = var.name_prefix

  accesses = var.accesses
  path     = var.path

  field_defaults = {
    # Kubernetes does not allow
    # SA that expire in less than 10 minutes
    "ttl" : 10 * 60
    "ttl_max" : 60 * 60
    "namespaces" : []
  }
}
