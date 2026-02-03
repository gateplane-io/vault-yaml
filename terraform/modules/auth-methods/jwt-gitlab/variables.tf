variable "description" {}

variable "path" {}

variable "gitlab_url" {}

variable "role_name" {}

variable "bound_audiences" {}

variable "protected" {
  default = false
}

variable "token_policies" {
  default = []
}

variable "authorizations" {
  /*
{
    "project/path": {
        "policies" : [
            "policy1", "policy2"
        ]
    }
}

*/

}