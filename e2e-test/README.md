<!--
Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
SPDX-License-Identifier: Elastic-2.0
-->

# Vault-YAML end-to-end test

This directory contains a destructive-but-ephemeral Terratest suite. It creates
a dedicated kind cluster, starts Vault or OpenBao in development mode, applies
shared Terraform prerequisites, and then reconciles the same `access.yaml` with
either the local Vault-YAML Terraform modules or Crossplane and the Helm chart.
It validates the resulting API objects through the CLI inside the server pod.

Nothing outside `e2e-test/` is created in the repository. Runtime infrastructure
is limited to the uniquely named kind cluster and is removed with deferred
cleanup.

## Requirements

- Go 1.23 or newer
- Terraform
- kind
- kubectl
- Podman by default, or another kind-supported container CLI
- Helm (when `E2E_RECONCILER=crossplane`)

## Run

```console
./run.sh
```

Both products are tested sequentially by default. Select one with:

```console
E2E_TARGET=vault ./run.sh
E2E_TARGET=openbao ./run.sh
```

Configuration variables:

| Variable | Default | Meaning |
| --- | --- | --- |
| `E2E_ROOT_TOKEN` | `e2e-test-token` | Development-mode root token. |
| `E2E_TARGET` | `both` | `vault`, `openbao`, or `both`. |
| `E2E_VAULT_VERSION` | `latest` | Tag appended to `hashicorp/vault`. |
| `E2E_OPENBAO_VERSION` | `latest` | Tag appended to `openbao/openbao`. |
| `E2E_CONTAINER_CLI` | `podman` | Container provider used by kind. |
| `E2E_RECONCILER` | `terraform` | Second phase: `terraform` or `crossplane`. |
| `E2E_CROSSPLANE_VERSION` | `2.3.3` | Crossplane Helm chart version (provider-vault v4 requires Crossplane 2.0+). |
| `E2E_PROVIDER_VAULT_VERSION` | `v4.0.0` | Tag for `xpkg.upbound.io/upbound/provider-vault`. |
| `E2E_CROSSPLANE_TIMEOUT` | `20m` | Timeout for each Crossplane installation/reconciliation phase. |
| `E2E_COMMAND_TIMEOUT` | `25m` | Safety timeout for an individual external command. |
| `E2E_TIMEOUT` | `60m` | Overall Go test timeout; keep this above the phase timeouts. |

`access.yaml` is the shared Vault-YAML input consumed by both reconcilers. Add
only behavior supported by both paths when parity is expected. Terraform role
templates live under `fixtures/`; Crossplane operational values live in
`reconcilers/crossplane/values.yaml`.

`expectations.yaml` independently defines CLI commands and JSON field
assertions. Keeping expectations separate prevents test-only data from entering
the Vault-YAML module input. Each expectation may set `reconciler` to `both`,
`terraform`, or `crossplane`; omission defaults to `both`:

```yaml
- name: Kubernetes auth role was generated
  reconciler: terraform
  command: [read, -format=json, auth/kubernetes/role/default-e2e-serviceaccount]
  assertions:
    data.bound_service_account_names: [e2e-serviceaccount]
```

Use `both` only for behavior expected to be equivalent across reconcilers. The
shared access fixture may include unsupported Crossplane principals as long as
the corresponding assertions are marked `terraform`.

## Phases and ownership

Every target uses two phases:

1. `terraform-prerequisites/` creates mounts, CAs, and auth backends.
2. `E2E_RECONCILER` selects either `reconcilers/terraform/` or
   `reconcilers/crossplane/` to own roles, policies, and attachments.

The two reconcilers are never active together. In Crossplane mode the harness
waits for the provider to report `Healthy=True`, then requires every managed
resource rendered by the `vault-yaml` release to report both `Ready=True` and
`Synced=True` before API assertions run.

Run the Crossplane matrix with:

```console
E2E_RECONCILER=crossplane ./run.sh
```
