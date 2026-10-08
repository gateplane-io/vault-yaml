<!-- BEGIN_TF_DOCS -->
# `vault-yaml` Terraform module

This directory is the public Terraform module. It accepts one decoded `vault-yaml` access document plus existing secrets-engine mounts and authentication methods. Top-level keys select internal submodule types, and each key contains an array so multiple mounts or auth methods of the same type are supported.

The module does not create mounts or configure the Vault provider. Callers retain ownership of those resources and pass their resource or data-source objects through `mount`.

## Usage

```hcl
module "vault_yaml" {
  source = "github.com/gateplane-io/vault-yaml.git//terraform"

  accesses = yamldecode(file("${path.module}/access.yaml"))

  mounts = {
    pki = [{
      mount                    = vault_mount.primary_pki
      issuer_id                = vault_pki_secret_backend_root_cert.primary.issuer_id
      templated_common_names   = { email = "{{identity.entity.name}}@example.com" }
      enable_conditional_roles = true
    }, {
      mount                  = vault_mount.partner_pki
      issuer_id              = vault_pki_secret_backend_issuer.partner.issuer_id
      templated_common_names = {}
    }]

    kubernetes = [{
      mount          = vault_kubernetes_secret_backend.production
      role_directory = "${path.module}/roles/kubernetes"
    }]

    ssh = [{
      mount         = vault_mount.ssh
      allowed_users = "{{identity.entity.name}}"
      default_user  = "{{identity.entity.name}}"
    }]

    vault = [{
      alias          = "adhoc"
      role_directory = "${path.module}/roles/vault"
    }]

    # Template-only engines that do not dispatch a role submodule.
    external = [{
      alias = "kv"
      mount = vault_mount.kvv2
    }]
  }

  auth_methods = {
    ldap = [{
      alias = "ldap"
      mount = vault_ldap_auth_backend.primary
    }, {
      alias = "partner_ldap"
      mount = vault_ldap_auth_backend.partner
    }]

    identity = [{
      alias = "identity"
    }]

    cert = [{
      alias               = "cert"
      mount               = vault_auth_backend.cert
      trusted_certificate = vault_pki_secret_backend_root_cert.primary.certificate
    }]
  }
}
```

See [`examples/complete`](examples/complete) for a complete Bring-Your-Own-Vault (BYOV) configuration.

## Mounts

`mounts` is an object keyed by supported secrets-engine type. Every key contains an array; each element is passed to one instance of that type's internal module.

| Key | Required fields per element | Optional fields per element |
| --- | --- | --- |
| `pki` | `mount`, `issuer_id` | `templated_common_names`, `name_prefix`, `enable_conditional_roles` |
| `kubernetes` | `mount`, `role_directory` | `name_prefix`, `enable_conditional_roles`, `name_template`, `kubernetes_labels` |
| `ssh` | `mount`, `allowed_users`, `default_user` | `name_prefix`, `enable_conditional_roles` |
| `vault` | `alias`, `role_directory` | `name_prefix`, `enable_conditional_roles` |
| `external` | `alias`, `mount` | none |

Public arrays are normalized into internal maps before dispatch. PKI, Kubernetes, and SSH instances are keyed by `mount.path`; mountless Vault/ad-hoc instances are keyed by `alias`. Managed engines are exposed to policy templates under their Vault mount paths. `external` entries are exposed under their explicit `alias`, allowing names such as `kv` without dispatching an internal role module.

Reordering an input array does not change Terraform module addresses.

## Authentication methods

`auth_methods` is an object keyed by supported authentication type. Every key contains an array, and every element requires an explicit `alias`. The alias is the first component of matching principals; for example, `alias = "partner_ldap"` handles principals beginning with `partner_ldap.`.

Aliases must be non-empty and unique across all auth types.

| Key | Required fields per element | Optional fields per element |
| --- | --- | --- |
| `ldap` | `alias`, `mount` | none |
| `identity` | `alias` | `exclusive` |
| `cert` | `alias`, `mount`, `trusted_certificate` | `exclusive` |
| `kubernetes` | `alias`, `mount` | none |
| `userpass` | `alias`, `mount` | `exclusive` |

Mounted auth instances are internally keyed by `mount.path`. Identity instances have no mount and are keyed by `alias`. Reordering an input array does not change Terraform module addresses.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accesses"></a> [accesses](#input\_accesses) | Decoded vault-yaml access document, typically produced with yamldecode(file(...)). | `any` | n/a | yes |
| <a name="input_auth_methods"></a> [auth\_methods](#input\_auth\_methods) | Authentication-method configurations grouped into arrays by supported type. Every entry requires an explicit principal alias. | <pre>object({<br/>    ldap       = optional(any, [])<br/>    identity   = optional(any, [])<br/>    cert       = optional(any, [])<br/>    kubernetes = optional(any, [])<br/>    userpass   = optional(any, [])<br/>  })</pre> | `{}` | no |
| <a name="input_mounts"></a> [mounts](#input\_mounts) | Secrets-engine configurations grouped into arrays by supported type. | <pre>object({<br/>    pki        = optional(any, [])<br/>    kubernetes = optional(any, [])<br/>    ssh        = optional(any, [])<br/>    vault      = optional(any, [])<br/>    external   = optional(any, [])<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_auth_methods"></a> [auth\_methods](#output\_auth\_methods) | Auth-method path and accessor map available to ad-hoc policy templates. |
| <a name="output_authorizations"></a> [authorizations](#output\_authorizations) | Authorizations grouped by auth-method principal key. |
| <a name="output_policies_list"></a> [policies\_list](#output\_policies\_list) | Flattened access-policy metadata produced by all configured secrets-engine modules. |
| <a name="output_secret_engines"></a> [secret\_engines](#output\_secret\_engines) | Secrets-engine path and accessor map available to ad-hoc policy templates. |
<!-- END_TF_DOCS -->
