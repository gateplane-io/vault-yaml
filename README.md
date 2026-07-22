# Vault / OpenBao Declarative Configuration

*Vault/OpenBao configuration for mere humans*


## 🚨 Problem statement

Configuring Vault/OpenBao at scale is *complex and opaque*.
It requires a steep learning curve and its flexibility exposes many configuration paths,
most of which are unnecessary for common organizational use cases and difficult to review consistently.

This project distills GatePlane’s operational experience with Vault/OpenBao
into a single, declarative configuration format that surfaces the most common
and security-relevant options explicitly.


## 📋 Overview

This project provides a declarative YAML format for configuring Vault and OpenBao that focuses on solving the critical security question: **"who has what access to what?"**

By defining secret engines, roles, policies, and access control in a single, human-readable YAML file, you get:

- **Simplified configuration** – Only the most common and security-relevant options are exposed explicitly
- **Auditable access control** – Clear visibility into who can access which resources
- **Reduced complexity** – Avoid the steep learning curve and many configuration paths of native Vault
- **GitOps-friendly** – Version control your entire access model alongside your infrastructure

The same access document can be reconciled through either:

- **Terraform**, using the modules under [`terraform/modules`](terraform/modules) and the working configuration under [`terraform`](terraform).
- **Crossplane**, using the Helm chart under [`charts/vault-yaml`](charts/vault-yaml), which renders Upbound `provider-vault` managed resources.

Terraform and Crossplane are alternative owners of the same desired Vault configuration. Never run both reconcilers against the same Vault objects concurrently. Crossplane support currently has documented feature limitations; see the [chart README](charts/vault-yaml/README.md) for its exact support matrix, prerequisites, and operational values. Component version scopes, release tags, and current compatibility are documented in [`COMPATIBILITY.md`](COMPATIBILITY.md).

## 📑 Table of Contents

<!--TOC-->

- [🚨 Problem statement](#-problem-statement)
- [📋 Overview](#-overview)
- [📑 Table of Contents](#-table-of-contents)
- [🏗️ Top-level Structure](#-top-level-structure)
  - [`type`](#type)
  - [`roles`](#roles)
  - [Static and Conditional Access](#static-and-conditional-access)
  - [The `access` block](#the-access-block)
  - [Authentication and *Principals*](#authentication-and-principals)
  - [`adhoc` - Ad-Hoc Vault Policies](#adhoc---ad-hoc-vault-policies)
- [🚀 Getting Started](#-getting-started)
  - [Choose a reconciler](#choose-a-reconciler)
  - [Prerequisites](#prerequisites)
  - [Starting fresh](#starting-fresh)
  - [Bring Your Own Vault (BYOV)](#bring-your-own-vault-byov)
- [🎯 GatePlane Services](#-gateplane-services)
- [📦 What `vault-yaml` manages](#-what-vault-yaml-manages)
- [⚖️ License](#-license)

<!--TOC-->

## 🏗️ Top-level Structure
The [`/access.example.yaml`](https://github.com/gateplane-io/vault-yaml/blob/main/access.example.yaml) file demonstrates all supported features with inline comments to guide you through them.

Each top-level key represents a logical Vault mount (secrets engine) or feature group:

```yaml
<pki-engine-path>:
  type: pki
  roles: {...}

<kubernetes-engine-path>:
  type: kubernetes
  roles: {...}

adhoc:
  type: vault
  roles: {...}
```

The key itself is the **mount path** in Vault (e.g., `pki`, `kubernetes`, or a custom path like `ssh/signer`). The special `adhoc` key is reserved for Vault policies not tied to any secrets engine.

### `type`

Defines the Vault engine or feature being configured.

#### Supported examples

* `kubernetes` - [`terraform/modules/secret-engines/kubernetes`](https://github.com/gateplane-io/vault-yaml/tree/main/terraform/modules/secrets-engines/kubernetes)


* `pki` - [`terraform/modules/secret-engines/pki`](https://github.com/gateplane-io/vault-yaml/tree/main/terraform/modules/secrets-engines/pki)

CA that generates/signs certificates to used for Code Signing, OpenVPN authentication, etc.

* `ssh` [`terraform/modules/secret-engines/ssh`](https://github.com/gateplane-io/vault-yaml/tree/main/terraform/modules/secrets-engines/ssh)

Currently works with the [agent-less SSH CA method](https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates).

* `vault` [`terraform/modules/secret-engines/vault`](https://github.com/gateplane-io/vault-yaml/tree/main/terraform/modules/secrets-engines/vault) (policies only)

Is used only by the `adhoc` key, to directly create templated Vault policies that do not adhere to secret engine use-cases.

* *more to come (AWS, GCP, Azure, Databases, etc)*

##### Policy generation

For each role defined in your YAML, `vault-yaml` automatically generates appropriate policies based on each secrets engine's use case of credential generation. These policies are then attached to all principals referenced in the role's `access` block.

### `roles`

Defines roles that map directly to Vault/OpenBao Secret Engine roles.

####  Example:

```yaml
roles:
  web:
    ttl: 7776000
    allowed_domains:
      - example.com
    access: [...]
```

Roles serve two purposes:

1. **Vault configuration**: They configure the underlying Vault secret engine role (e.g., setting TTL, allowed domains, certificate parameters)
2. **Access control**: They define who can use this role through the `access` block

The keys you define in a role (e.g., `ttl`, `allowed_domains`) map directly to the corresponding Vault Terraform provider resource for that secret engine type. For example, `allowed_domains` corresponds to the same field in [`pki_secret_backend_role`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_role).

The `access` key is explained further below.

### Static and Conditional Access

Roles can define both static and conditional access:

- **Static access**: Principals have immediate, permanent access to use the role. No approval is required.

- **Conditional access**: Principals must request access and receive approval before using the role. This is implemented through the [GatePlane Policy Gate](https://github.com/gateplane-io/vault-plugins?tab=readme-ov-file#policy-gate) plugin and is ideal for:
  - Sensitive operations requiring oversight
  - Multi-person approval workflows
  - Situations requiring justification documentation
  - Temporary access scenarios (hotfixes, maintenance, onboarding)

You can define both `static` and `conditional` access on the same role, allowing different levels of access for different users.

#### Example: Conditional access for user onboarding (certificate generation)

In this example, anyone can request a client certificate, but it must be approved by an Onboarder before being issued:

```yaml
roles:
  client-generate:
    client_flag: true
    ttl: 31536000
    access:
      conditional:
        requestors:
          - "ldap.groups.Everyone"
        approvers:
          - "ldap.groups.Onboarders"
        required_approvals: 1
        require_justification: false
```


### The `access` block

The `access` block is defined under each role to control who may use that role. It accepts two optional sub-blocks:

#### `static`

Grants immediate, permanent access to principals without requiring approval. Accepts a *list* (`[]`) of principal strings.

Use this for:
- Automated systems that need constant access
- Teams that require ongoing access to resources
- Operations that don't need oversight

```yaml
access:
  static:
    - "ldap.groups.Administrators"
    - "ldap.users.jdoe"
```

#### `conditional`

Requires approval before access is granted. Accepts a *map* (`{}`) with the following keys:

- `requestors`: List of principals who can submit access requests
- `approvers`: List of principals who can approve requests
- `required_approvals` *(optional, default: 1)*: Minimum number of approvals required
- `require_justification` *(optional, default: false)*: Whether requestors must provide a reason

Use this for:
- Production break-glass scenarios
- Temporary elevated privileges
- Security-sensitive operations
- Audit trail requirements

```yaml
access:
  conditional:
    requestors:
      - "ldap.groups.Developers"
    approvers:
      - "ldap.groups.KubernetesAdministrators"
      - "ldap.groups.cab"
    required_approvals: 2
    require_justification: true
```

A role can have both `static` and `conditional` access defined:

```yaml
access:
  static:
    - "ldap.groups.Administrators"
  conditional:
    requestors:
      - "ldap.groups.Developers"
    approvers:
      - "ldap.groups.Administrators"
    required_approvals: 1
    require_justification: true
```


### Authentication and *Principals*

Principals are represented as strings that combine the authentication method with the identity. This format tells `vault-yaml` **how** the user authenticates and **who** they are.

#### Supported principal formats

**1. LDAP authentication**

Format: `ldap.groups.<group-name>` or `ldap.users.<username>`

These principals are authenticated through your configured LDAP auth method. The user's username and group membership are pulled directly from your LDAP directory.

Examples:
- `ldap.groups.Developers`
- `ldap.users.jdoe`

**2. Vault/OpenBao Identities**

Format: `identity.entity_id.<id>` or `identity.entity_name.<name>` or `identity.group_id.<id>` or `identity.group_name.<name>`

These principals reference entities or groups stored in Vault/OpenBao's identity system. They can be created manually or automatically through auth methods.

Examples:
- `identity.entity_id.f84a6248-b907-4119-bdd7-f47c8bf40bbf`
- `identity.entity_name.entity_e13c9ca6`
- `identity.group_id.30210932-96a2-f3de-bc39-24e49d543832`
- `identity.group_name.InternalAdmins`

> **Note:** If an Entity or Group does not exist, but is referenced in the `accesses.yaml`, `terraform apply` will exit with an error.

> **Note:** Avoid managing [external Vault groups](https://developer.hashicorp.com/vault/docs/concepts/identity#external-vs-internal-groups) with `vault-yaml`, as this can cause Terraform drift issues.

**3. Username and Password**

Format: `userpass.<username>`

These principals reference usernames created through the "[Username and Password (userpass)](https://developer.hashicorp.com/vault/docs/auth/userpass)" Auth Method of Vault/OpenBao.

Examples:
- `userpass.jdoe`
- `userpass.mitchellh`

> **Note:** If the username does not exist, but is referenced in the `accesses.yaml`, `terraform apply` will exit with an error.


**4. Client Certificates (mTLS)**

Format: `cert.<common_name>[::ip_bind=true]`

These principals reference Client Certificate Common Names of x509 Certificates authenticated through the "[TLS Certificates](https://developer.hashicorp.com/vault/docs/auth/cert)" Auth Method of Vault/OpenBao.

`ip_bind`: This principal *extension* is used for machine attestation, such as Kubernetes Nodes, Crypto Validators, etc.
Terraform resolves the domain found in principal's Common Name (IPv4 and IPv6 addresses) and allows the Vault / OpenBao tokens created by the principal's certificate to be used **only** by these IPs.

> **Note:** The `ip_bind` extension **must not** be used for machines with non-static IP addresses. The Vault / OpenBao token created through an IP-bound certificate cannot be used outside the machine with the resolved IPs

> **Note:** If the `ip_bind` extension is used, but the domain found in the principal cannot resolve, Terraform will fail. Additionally, it is possible to change the default DNS server of the Terraform runner by configuring [Terraform DNS Provider](https://registry.terraform.io/providers/hashicorp/dns/latest/docs)


Examples:
- `cert.example.com`
- `cert.jdoe@mail.example.com`
- `cert.node1.example.com::ip_bind=true`


**5. Kubernetes Service Accounts**

Format: `kubernetes.<namespace>.<service_account>`

These principals reference Kubernetes Service Accounts, authenticated to Vault/OpenBao through the [Kubernetes Auth Method](https://developer.hashicorp.com/vault/docs/auth/kubernetes).

Vault/OpenBao validates the Service Account token of a workload against the issuing Kubernetes cluster, and reads its JWT claims, that contain `namespace` and `serviceAccountName`.

Example:
- `kubernetes.secrets-management.external-secrets` - A Principal that will be allowed to access a read-only role in KV backend, presumably an [External Secrets Operator](https://external-secrets.io/latest/) deployment.

**6. JWT authentication** *(Work in Progress)*

Format: `jwt.<role>.<jwt-sub>`

Used for CI/CD pipelines and service accounts authenticating via JWT.

Example:
- `jwt.cicd.org/repo1` - Matches JWT `sub` claim `org/repo1` from the JWT auth mount with role `cicd`

### `adhoc` - Ad-Hoc Vault Policies

The `adhoc` section defines custom Vault/OpenBao policies that aren't tied to any specific Secrets Engine. Use this when you need fine-grained control over paths and capabilities that don't fit into the standard secret engine role model.

#### How it works

Each role in the `adhoc` section references a **policy template file** (`.hcl`) that contains the actual Vault policy rules. The template can reference variables for dynamic path generation.

#### Example:
```yaml
adhoc:
  type: vault
  roles:
    secrets-personal:
      access:
        static:
          - ldap.groups.Everyone
```

This configuration creates a policy from the template file [`roles/vault/secrets-personal.hcl`](https://github.com/gateplane-io/vault-yaml/blob/main/roles/vault/secrets-personal.hcl) and attaches it to all users in the `Everyone` LDAP group.

#### Template variables

Your policy templates can access these pre-defined variables:
- **`secrets_engines`** - A map of all configured secret engines and their mount paths
- **`auth_methods`** - A map of all configured auth methods and their mount paths
- **`policy_name`** - The generated Vault policy name
- **`access`** - For `for_each: true`, the original complete principal string
- **`access_name`** - For `for_each: true`, the principal's path-friendly semantic name

`access_name` removes any `::` options, removes principal grammar prefixes, joins semantic components with `-`, replaces non-alphanumeric runs with `-`, trims edge hyphens, and preserves case. For example, `kubernetes.default.serviceaccount` becomes `default-serviceaccount`, `ldap.groups.Platform.Administrators` becomes `Platform-Administrators`, and `cert.test@example.com` becomes `test-example-com`. Templates must use `access_name` instead of splitting `access` themselves.

For identity name principals, this readable template value does not change authorization behavior: Terraform still resolves the referenced entity or group name to its Vault ID before attaching policies.

This lets you write policies that dynamically reference your infrastructure without hardcoding paths.

For example, in a template:
```hcl
# The 'secrets_engines' parameter is templated by Terraform
# The {{ identity.entity.name }} directive is templated by Vault/OpenBao
path "${secrets_engines["kv"]["path"]}/data/users/{{ identity.entity.name }}" {
  capabilities = ["create", "read", "update", "delete"]
}
```

See [`terraform/main.tf#L66`](https://github.com/gateplane-io/vault-yaml/blob/main/terraform/main.tf#L66) for how these maps are constructed.

## 🚀 Getting Started

### Choose a reconciler

Use exactly one reconciler for each external Vault object.

#### Terraform

Terraform consumes the access document with `yamldecode` and uses the modules under [`terraform/modules`](terraform/modules). This remains the path with the broadest feature support, including GatePlane conditional access and identity lookup by name.

#### Crossplane

The Helm chart accepts the same unmodified access document through `--set-file` and renders Crossplane managed resources:

```bash
helm upgrade --install vault-yaml charts/vault-yaml \
  --namespace vault-system \
  --create-namespace \
  --values crossplane-values.yaml \
  --set-file accessFile=access.yaml
```

Crossplane deployment settings (including existing mount details, auth integrations, provider references, Kubernetes role definitions, and ad-hoc policy templates) are supplied separately under the key `_vaultYaml`.

Do not pass the access document directly with Helm `-f`, rather set it to the `accessFile` key as raw string.

See [`charts/vault-yaml/README.md`](charts/vault-yaml/README.md) before installation. It documents supported principals, generated resources, provider setup, lifecycle defaults, render warnings, and current gaps such as conditional-access reconciliation and identity lookup by name.

### Prerequisites

All deployments require:

- A Vault or OpenBao server that is running and accessible.
- Existing secrets-engine and auth-method mounts used by the access document.

Terraform additionally requires Terraform and the Terraform Vault provider configured with suitable authentication.

Crossplane additionally requires Kubernetes, Helm, Crossplane, the [Upbound `provider-vault`](https://github.com/upbound/provider-vault) CRDs, and a suitable `ProviderConfig`. The chart can optionally render the provider package and `ProviderConfig`, but it does not install Crossplane or create Vault mounts.

### Starting fresh

If you're setting up a new Vault/OpenBao instance:

1. **Create a Vault/OpenBao instance** using the [Hashicorp official Terraform provider](https://registry.terraform.io/providers/hashicorp/vault/latest).

2. **Configure authentication and secrets engines** using Terraform resources. For example:
   - Mount a secrets engine: [`vault_mount`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount)
   - Add Kubernetes integration: [`vault_kubernetes_secret_backend`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_secret_backend)
   - Configure LDAP authentication: [`vault_ldap_auth_backend`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/ldap_auth_backend)

3. **Connect your mounts to `vault-yaml` modules** by passing the mount path to the appropriate modules in `terraform/modules/secrets-engines` or `terraform/modules/auth-methods`. See [`main.tf`](https://github.com/gateplane-io/vault-yaml/blob/main/terraform/main.tf#L34) for a complete example.

### Bring Your Own Vault (BYOV)

You can use vault-yaml with **existing Vault/OpenBao instances** - without replacing or disrupting your current configuration.

In this repository, the separation between `vault-yaml` and BYOV resources can be seen under `terraform/` directory. The `byov.tf` files are meant to pre-date the `vault-yaml` files (`main.tf`, `gateplane.tf`)

#### Gradual Migration

`vault-yaml` works alongside your existing setup:

- **Existing roles and policies are preserved** - `vault-yaml` does not delete or modify your existing configuration (`terraform plan` will fail if resources with the same name exist)
- **New resources are added incrementally** - your `accesses.yaml` file provisions new roles and policies defined in the YAML
- **No disruption to existing workflows** - your current operations continue uninterrupted

#### How it works

Simply reference your existing Secrets Engines and Auth Methods when configuring `vault-yaml` modules:

1. **For existing secrets engines**: Connect an existing mount (e.g., `/pki` or `/kubernetes`) to the corresponding `vault-yaml` module using the `mount` variable. The module will create new roles defined in your YAML alongside any existing roles.

2. **For existing auth methods**: Reference your existing auth methods in the configuration. This enables `vault-yaml` to use principals (users, groups, entities) that are already authenticated through those auth methods.

#### Example

If you have an existing Kubernetes engine referenced by Terraform with `vault_kubernetes_secret_backend.kubernetes`, that already contains legacy roles:

```hcl
module "kubernetes" {
  source = "github.com/gateplane-io/vault-yaml.git//terraform/modules/secrets-engines/kubernetes"

  // Tying the vault-yaml configuration with existing Secrets Engine
  mount = vault_kubernetes_secret_backend.kubernetes

  // The directory where Kubernetes roles are defined (roles/kubernetes/<role_name>.yaml)
  role_directory = "./roles/kubernetes"
  // The `yamldecode` of your accessess.yaml file
  accesses       = local.accesses
}
```

Your existing roles remain untouched, and the new roles defined in the `accessess.yaml` are added alongside them.

This approach allows you to **gradually adopt** `vault-yaml`'s declarative management style without requiring a risky "big bang" migration.

## 🎯 GatePlane Services

The GatePlane Policy Gate plugin is free and fully included with `vault-yaml` under the Elastic V2 License, providing conditional access, approval workflows, and time-bound credentials.

For enhanced visibility, you can subscribe to [GatePlane Services](https://gateplane.io) which adds real-time notifications (Slack, Teams, Discord) and access metrics/analytics to help you track usage patterns and identify bottlenecks.

To enable GatePlane Services, add/uncomment the `gateplane_services` module to your [`terraform/gateplane.tf`](https://github.com/gateplane-io/vault-yaml/blob/main/terraform/gateplane.tf) file:

After applying the configuration, run `terraform output gateplane_services_output` and send the output to `services@gateplane.io` to activate your subscription.

## 📦 What `vault-yaml` manages

`vault-yaml` focuses on **access control and role management**. Here's what's in scope:

✅ **Managed by `vault-yaml`:**
- Secret engine roles (e.g., PKI roles, Kubernetes roles, SSH roles)
- Policies associated with those roles
- Role-to-principal assignments (who can use which role)
- Ad-hoc Vault policies defined in templates
- Conditional access using GatePlane plugins (*currently through the Terraform reconciler only*)

❌ **Managed separately (not by `vault-yaml`):**
- Vault/OpenBao server configuration
- Authentication method setup (LDAP, JWT, etc.)
- Secret engine mounts and basic configuration
- Identity entities and groups (these must exist first)
- Root tokens, recovery keys, and server certificates
- Audit logs and monitoring setup

**Think of it this way:** `vault-yaml` builds the access layer on top of infrastructure you've already configured. You set up the Vault/OpenBao server, auth methods, and secret engines - then `vault-yaml` helps you manage "who has what access to what" in a declarative, auditable way.

## ⚖️ License

This project is licensed under the [Elastic License v2](https://www.elastic.co/licensing/elastic-license).

This means:

- ✅ You can use, fork, and modify it for **yourself** or **within your company**.
- ✅ You can submit pull requests and redistribute modified versions (with the license attached).
- ❌ You may **not** sell it, offer it as a paid product, or use it in a hosted service (e.g., SaaS).
- ❌ You may **not** re-license it under a different license.

In short: You can use and extend the code freely, privately or inside your business - just don’t build a business around it without our permission.
[This FAQ by Elastic](https://www.elastic.co/licensing/elastic-license/faq) greatly summarizes things.

See the [`./LICENSES/Elastic-2.0.txt`](./LICENSES/Elastic-2.0.txt) file for full details.
