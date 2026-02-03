module "parser" {
  source = "../../role-parser"

  name_prefix = var.name_prefix

  accesses = var.accesses
  path     = var.path

  field_defaults = {
    "ttl" : 10 * 60

    "organization" : []
    "country" : []
    "locality" : []

    "key_usage" : ["DigitalSignature", "KeyAgreement", "KeyEncipherment"]
    "ext_key_usage" : []

    "allowed_domains" : []
    "templated_common_name" : []

    "client_flag" : true
    "server_flag" : false
  }
}
