<!--
Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
SPDX-License-Identifier: Elastic-2.0
-->

# Principal parser

Shared parser for auth-method principal strings found in policy access mappings.

## Input format

```text
<principal_key>.<principal_body>[::key=value,key2=value2]
```

Examples:

```text
ldap.groups.Developers
kubernetes.default.external-secrets
auth-cert.app.example.com::ip_bind=true
```

## Usage

```hcl
module "principal_parser" {
  source = "../../helpers/principal-parser"

  policies_list = var.policies_list
  principal_key = var.principal_key
}
```

For `kubernetes.default.external-secrets`, an entry in `principals` resembles:

```hcl
{
  "default.external-secrets" = {
    access    = "kubernetes.default.external-secrets"
    principal = "default.external-secrets"
    parts     = ["default", "external-secrets"]
    policies  = ["policy-name"]
  }
}
```

The parser:

- Selects only accesses beginning with the exact `<principal_key>.` prefix.
- Aggregates policy keys targeting the same complete access string.
- Removes the principal key while preserving the full remaining name.
- Exposes dot-separated `parts` for auth-method-specific interpretation.
- Parses optional settings with `jsondecode`, falling back to strings.

Consumers remain responsible for validating their required segment count and
mapping segments to auth-specific fields.

## Tests

```console
terraform init -backend=false
terraform test
```

The tests are plan-only and the module uses no providers or resources.
