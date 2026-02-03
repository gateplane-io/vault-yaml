variable "name_prefix" {
  default = ""
}

variable "roles_conditional" {}

variable "policies" {
}

variable "vault_addr" {
  default = "http://127.0.0.1:8200"
  type    = string
}
