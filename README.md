# Vault / OpenBao Declarative Configuration

*Vault/OpenBao configuration for mere humans*

## Problem statement

Configuring Vault/OpenBao at scale is *complex and opaque*.
It requires a steep learning curve and its flexibility exposes many configuration paths,
most of which are unnecessary for common organizational use cases and difficult to review consistently.

This project distills GatePlane’s operational experience with Vault/OpenBao
into a single, declarative configuration format that surfaces the most common
and security-relevant options explicitly.

## Overview

This repository defines Vault (or OpenBao) configuration using a declarative YAML format.
The goal is to solve the "*who has what access where*" problem,
by managing secret engines, roles, policies, and access control in a human-readable, auditable way.

This YAML schema is consumed by Terraform modules (under `/terraform/modules`).
Example code is available under `/terraform`.

*The Vault resources referenced in the YAML need to be already defined.*
This allows for integrating this configuration management into existing configuration (and Terraform codebase).

## Top-level Structure
The [`/access.example.yaml`](https://github.com/gateplane-io/vault-yaml/blob/main/access.example.yaml) file
serves as showcase of the implemented features, and contains comments to guide through them.

Each top-level key represents a logical Vault mount or feature group.
```yaml
<path-or-logical-name>:
  type: <engine-type>
  roles: {...}
  roles_conditional: {...}
```

### `type`

Defines the Vault engine or feature being configured.

#### Supported examples:

* `pki` - [`terraform/modules/secret-engines/pki`](https://github.com/gateplane-io/vault-yaml/tree/main/terraform/modules/secret-engines/pki)

Can be used for code signing, OpenVPN authentication, etc.
* `kubernetes` - [`terraform/modules/secret-engines/kubernetes`](https://github.com/gateplane-io/vault-yaml/tree/main/terraform/modules/secret-engines/kubernetes)
* `ssh` [`terraform/modules/secret-engines/ssh`](https://github.com/gateplane-io/vault-yaml/tree/main/terraform/modules/secret-engines/ssh)

Currently works with the [agent-less SSH CA method](https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates).
* `vault` (policies only)

Is used only by the `adhoc` key, to directly create templated Vault policies that do not adhere to secret engine use-cases.

##### Each type contains a set of pre-configured Policies, that are generated for each role and automatically attached to the referenced principals for that role.

### `roles`

Defines static roles that map directly to Vault Secret Engine roles.

####  Example:

```yaml
roles:
  web:
    ttl: 7776000
    allowed_domains:
      - example.com
    access: [...]
```

These roles typically:

* issue credentials
* define permissions
* are immediately usable

Keys are mostly compatible with Terraform provider resources for each role: (e.g.: `allowed_domains`)

The `access` key is explained further below.

### `roles_conditional` *(WIP)*

Defines roles that require approval or workflow before use.
They are implemented through [GatePlane Policy Gate](https://github.com/gateplane-io/vault-plugins?tab=readme-ov-file#policy-gate).

These roles:
* are not directly usable
* require request + approval
* are intended for sensitive operations (e.g. admin roles)

#### Example:
A case where a user certificate must be generated/issued (only) when onboarding
a new member. Generation has to be approved by an individual onboarder.

```yaml
roles_conditional:
  client-generate:
    access:
      requestors: ["ldap.groups.Everyone"]
      approvers: ["ldap.groups.Onboarders"]
```

### The `access` block

Defines who may use a role or policy.

* For `roles` it accepts a list of *Principals*.

* For `roles_conditional` it accepts a map.

The keys `requestors` and `approvers` each contain a list of *Principals*.
Additionally, they `required_approvals` and `require_justification` are accepted.

### Authentication and *Principals*:

The way this configuration schema handles principals is through strings
that contain how one was authenticated and statements that hold true for that principal.

#### Examples

* `ldap.groups.Developers`

The LDAP group of `Developers`

* `ldap.users.jdoe`

The LDAP user of `jdoe`

* `jwt.cicd.org/repo1` (`<auth-key>.<role>.<JWT sub>`) *(WIP)*

The owner of the JWT received from a JWT Auth Method, authenticated against the
JWT role `cicd` with its JWT `sub` claim equal to `org/repo1`

### `adhoc` - Ad-Hoc Vault Policies

The `adhoc` section defines arbitrary Vault policies that are not tied to any specific secret engine.

Policies are generated from template files and attached to users or groups.

#### Example:
```yaml
adhoc:
  roles:
    secrets-personal:
      access:
        - ldap.groups.Everyone
```

The Policy is templated from [`roles/vault/secrets-personal.hcl`](https://github.com/gateplane-io/vault-yaml/blob/main/roles/vault/secrets-personal.hcl)

The `secret_engines` and `auth_methods` maps are available to be used by the templates.


## License

This project is licensed under the [Elastic License v2](https://www.elastic.co/licensing/elastic-license).

This means:

- ✅ You can use, fork, and modify it for **yourself** or **within your company**.
- ✅ You can submit pull requests and redistribute modified versions (with the license attached).
- ❌ You may **not** sell it, offer it as a paid product, or use it in a hosted service (e.g., SaaS).
- ❌ You may **not** re-license it under a different license.

In short: You can use and extend the code freely, privately or inside your business - just don’t build a business around it without our permission.
[This FAQ by Elastic](https://www.elastic.co/licensing/elastic-license/faq) greatly summarizes things.

See the [`./LICENSES/Elastic-2.0.txt`](./LICENSES/Elastic-2.0.txt) file for full details.
