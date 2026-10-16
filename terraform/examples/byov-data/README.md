# BYOV with existing mount data

This example onboards existing Vault/OpenBao objects without declaring them as Terraform resources in this workspace:

- A Kubernetes secrets engine is read through `vault_generic_secret` at `sys/mounts/<path>`.
- A userpass auth method is read through `vault_auth_backend`.
- A certificate auth method is represented by an object containing only `path` and `accessor`.

The `vault-yaml` module does not take ownership of these mounts or auth methods. It manages the Kubernetes role, generated policy, userpass policy attachment, and certificate role described by `access.yaml`.

## Before planning

The target Vault/OpenBao instance must already contain:

- A Kubernetes secrets engine at `staging/cluster01`, or the path supplied through `kubernetes_mount_path`.
- A userpass auth method at `userpass`, or the path supplied through `userpass_auth_path`.
- A userpass user named `alice`.
- A certificate auth method at `cert`, or the path supplied through `cert_auth_path`.

The provider identity must be able to read the selected entries under `sys/mounts` and `sys/auth`, and manage the role, policy, and auth attachments created by the module.

Obtain the certificate auth accessor with:

```console
vault auth list -format=json
```

Configure the Vault provider through its standard environment variables and provide the certificate inputs without committing credentials or certificate material:

```console
export VAULT_ADDR=https://vault.example.com
export VAULT_TOKEN=...

terraform init
terraform plan \
  -var='cert_auth_accessor=auth_cert_01234567' \
  -var='cert_trusted_certificate_file=/absolute/path/to/client-ca.pem'
```

Review the plan for generated names that already exist. Vault endpoints commonly use create-or-update behavior, so an unmanaged remote role or policy with the same name may be changed during apply rather than reported as a Terraform ownership conflict.
