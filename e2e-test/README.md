<!--
Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
SPDX-License-Identifier: Elastic-2.0
-->

# Vault-YAML end-to-end test

This directory contains a destructive-but-ephemeral Terratest suite. It creates
a dedicated kind cluster, starts Vault or OpenBao in development mode, applies
the local Vault-YAML Terraform modules, and validates the resulting API objects
through the CLI running inside the server pod.

Nothing outside `e2e-test/` is created in the repository. Runtime infrastructure
is limited to the uniquely named kind cluster and is removed with deferred
cleanup.

## Requirements

- Go 1.23 or newer
- Terraform
- kind
- kubectl
- Podman by default, or another kind-supported container CLI

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
| `E2E_TIMEOUT` | `30m` | Overall Go test timeout. |

`access.yaml` is the Vault-YAML input consumed by Terraform. Add engine roles
and static access there, with matching role templates under `fixtures/`.

`expectations.yaml` independently defines CLI commands and JSON field
assertions. Keeping expectations separate prevents test-only data from entering
the Vault-YAML module input.

The initial scenario intentionally excludes conditional access and credential
issuance. It validates configuration, roles, policies, and policy attachment.
