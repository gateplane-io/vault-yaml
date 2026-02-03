
variable "description" {
  type    = string
  default = "JWT authentication method"
}

variable "path" {
  default = "oidc"
}

variable "policies_list" {
  description = "The full list of policies created by the Secrets Engine blocks"
  # type        = list(map(any))
}

variable "principal_key" {
  description = "The key to by used in Principals (e.g: `<key>.users.jdoe`)"
  default     = "oidc"
}


variable "default_role" {
  default = "user"
}
