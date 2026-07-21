<!--
Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
SPDX-License-Identifier: Elastic-2.0
-->

# Kubernetes auth-method module

Kubernetes principals use this format:

```text
<principal_key>.<namespace>.<serviceaccount_name>
```

For example:

```text
kubernetes.default.external-secrets
```

## Plan-only tests

The native Terraform/OpenTofu tests use a mocked Vault provider. They evaluate
principal parsing and planned resource attributes without contacting
Vault/OpenBao and without applying resources.

From the repository root:

```console
tofu -chdir=terraform/modules/auth-methods/kubernetes init -backend=false
tofu -chdir=terraform/modules/auth-methods/kubernetes test
```

With Terraform, use the equivalent commands:

```console
terraform -chdir=terraform/modules/auth-methods/kubernetes init -backend=false
terraform -chdir=terraform/modules/auth-methods/kubernetes test
```

Initialization downloads only the provider schema needed by the mock provider.
The tests themselves all use `command = plan`; they do not require a Vault
address or token.

The suite covers:

- Namespace and ServiceAccount parsing and role binding.
- Multiple Kubernetes principals.
- Policy aggregation and lowercase normalization.
- Custom `principal_key` values.
- Optional principal settings using `::key=value` notation.
