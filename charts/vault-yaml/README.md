# Crossplane chart for `vault-yaml`

This Helm chart renders a `vault-yaml` access document into Crossplane managed resources for Upbound `provider-vault`.

It manages Vault/OpenBao roles, policies, and supported static principal bindings. It does **not** manage Vault/OpenBao itself or the mounts on which those resources depend.

## Contents

- [Ownership and prerequisites](#ownership-and-prerequisites)
- [Installation](#installation)
- [Input model](#input-model)
- [Access document](#access-document)
- [Operational values](#operational-values)
- [Generated policies and names](#generated-policies-and-names)
- [PKI secrets engines](#pki-secrets-engines)
- [Kubernetes secrets engines](#kubernetes-secrets-engines)
- [SSH secrets engines](#ssh-secrets-engines)
- [Ad-hoc policies](#ad-hoc-policies)
- [Static principals](#static-principals)
- [Conditional access and render warnings](#conditional-access-and-render-warnings)
- [Lifecycle and ownership](#lifecycle-and-ownership)
- [Rendering and validation](#rendering-and-validation)
- [Current limitations](#current-limitations)

## Ownership and prerequisites

All secrets-engine and auth-method mounts must already exist. The chart does not create, configure, or delete:

- Vault or OpenBao servers.
- PKI, Kubernetes, SSH, KV, or other secrets-engine mounts.
- PKI root/intermediate CAs or issuers.
- SSH certificate authorities.
- LDAP, certificate, Kubernetes, or other auth-method mounts.
- Kubernetes secrets-backend connections.
- Vault identity entities or groups.
- Kubernetes ServiceAccounts or RBAC objects in workload clusters.
- Crossplane itself.

The chart creates configuration within existing mounts:

- PKI, Kubernetes secrets-engine, and SSH roles.
- Policies generated for those roles.
- User-supplied ad-hoc policies.
- LDAP user/group policy mappings.
- Vault identity entity/group policy attachments by immutable ID.
- Certificate-auth roles when explicitly enabled.
- Kubernetes-auth roles for static ServiceAccount principals when explicitly enabled.

Terraform and Crossplane must never manage the same Vault objects concurrently.

## Installation

The chart expects Crossplane and the `provider-vault` CRDs to exist. It is built against:

```text
xpkg.upbound.io/upbound/provider-vault:v4.0.0
```

Supply the access document through `--set-file`. Do not pass it directly with `-f`: its top-level keys are Vault paths, not Helm operational values.

```bash
helm upgrade --install vault-yaml charts/vault-yaml \
  --namespace vault-system \
  --create-namespace \
  --values crossplane-values.yaml \
  --set-file accessFile=access.yaml
```

If all operational defaults are suitable, `--values` may be omitted:

```bash
helm upgrade --install vault-yaml charts/vault-yaml \
  --namespace vault-system \
  --create-namespace \
  --set-file accessFile=access.yaml
```

Always render and review the complete output first:

```bash
helm lint charts/vault-yaml \
  --set-file accessFile=access.yaml

helm template vault-yaml charts/vault-yaml \
  --values crossplane-values.yaml \
  --set-file accessFile=access.yaml
```

A successful Helm installation means Kubernetes accepted the manifests. It does not mean Crossplane has reconciled the external Vault resources. Check managed-resource conditions:

```bash
kubectl get managed
```

## Input model

The release has two deliberately separate inputs:

| Input | Purpose | How to supply it |
| --- | --- | --- |
| `accessFile` | The portable `vault-yaml` domain document: mounts, roles, and access. | `--set-file accessFile=access.yaml` |
| `_vaultYaml` | Crossplane/provider settings and deployment-specific data that does not belong in the portable access document. | A Helm values file or `--set` |

This separation lets the same access document remain consumable by Terraform without a Helm-specific wrapper.

## Access document

Each top-level entry is an existing Vault path and contains a `type` and `roles` map:

```yaml
pki/org-ca:
  type: pki
  roles: {}

staging/cluster01:
  type: kubernetes
  roles: {}

staging/vms:
  type: ssh
  roles: {}

adhoc:
  type: vault
  roles: {}
```

Supported `type` values are `pki`, `kubernetes`, `ssh`, and `vault`.

The ad-hoc renderer specifically reads the top-level key `adhoc`. Therefore `type: vault` must be placed at `adhoc`; a `vault` entry under another top-level key is accepted by structural validation but does not render policies.

Every engine role uses this access shape:

```yaml
access:
  static:
    - ldap.groups.Operators
  conditional:
    requestors:
      - ldap.groups.Developers
    approvers:
      - ldap.groups.Operators
    required_approvals: 1
    require_justification: true
    description: Temporary operator access
```

Current chart behavior is:

- `access.static` is rendered and attaches generated policies to supported principals.
- `access.conditional` causes normal engine roles and policies to be rendered, but the GatePlane approval workflow is **not** reconciled. A render warning is emitted for PKI, Kubernetes, and SSH roles.
- A PKI, Kubernetes, or SSH role with neither a non-empty `static` list nor a `conditional` key is skipped entirely.
- An ad-hoc role without `for_each` renders its shared policy even if `access.static` is empty.
- Ad-hoc principal bindings are derived only from `access.static`; ad-hoc conditional access is not reconciled.

## Operational values

Operational values live under `_vaultYaml`.

### Provider installation and configuration

The chart can optionally install the provider package and create a `ProviderConfig`:

```yaml
_vaultYaml:
  provider:
    install: true
    package: xpkg.upbound.io/upbound/provider-vault:v4.0.0
    configRef: default
    config:
      create: true
      name: default
      address: https://vault.example.com:8200
      skipTlsVerify: false
      credentialsSecretRef:
        namespace: crossplane-system
        name: vault-provider-creds
        key: credentials
```

| Value | Default | Meaning |
| --- | --- | --- |
| `provider.install` | `false` | Render a cluster-scoped Crossplane `Provider` named `upbound-provider-vault`. |
| `provider.package` | `xpkg.upbound.io/upbound/provider-vault:v4.0.0` | Provider package used when installation is enabled. |
| `provider.configRef` | `default` | `ProviderConfig` referenced by every managed resource. |
| `provider.config.create` | `false` | Render a `vault.upbound.io/v1beta1` `ProviderConfig`. |
| `provider.config.name` | `default` | Name of the rendered `ProviderConfig`. Set `provider.configRef` to the same name when creating it here. |
| `provider.config.address` | Example URL | Vault/OpenBao API address; required when creating the config. |
| `provider.config.skipTlsVerify` | `false` | Disable TLS certificate verification. Do not enable this in production. |
| `provider.config.credentialsSecretRef` | See `values.yaml` | Existing Secret reference used by the provider. |

The referenced Secret must already exist. Never put a Vault token directly in Helm values, a ConfigMap, or committed configuration.

### Engine mount settings

Every `pki`, `kubernetes`, or `ssh` path in the access document requires an exact matching key under `_vaultYaml.secrets.<type>.mounts`:

```yaml
_vaultYaml:
  secrets:
    pki:
      mounts:
        pki/org-ca: {}
    kubernetes:
      mounts:
        staging/cluster01: {}
    ssh:
      mounts:
        staging/vms: {}
```

A missing match fails Helm rendering with the access path in the error.

## Generated policies and names

For PKI, Kubernetes, and SSH roles, the external Vault policy name is:

```text
<type>-<role-name>-<last-mount-path-segment>
```

Examples:

```text
pki-web-org-ca
kubernetes-deployer-cluster01
ssh-admin-vms
```

Ad-hoc names use a separate convention described under [Ad-hoc policies](#ad-hoc-policies).

External Vault role names remain exactly the role keys from the access document. Policy names are lowercased when added to principal bindings.

Kubernetes managed-resource names are not external Vault names. The chart:

1. Builds a name from the resource type, Vault path, and role or principal.
2. Lowercases it and replaces characters outside `[a-z0-9-]` with `-`.
3. Truncates the readable portion.
4. Appends the first eight characters of a SHA-256 hash of the unnormalized name.
5. Limits the final name to 63 characters.

Original Vault paths and role names are retained in `vault-yaml.gateplane.io/path` and `vault-yaml.gateplane.io/role` annotations where that renderer supplies metadata.

## PKI secrets engines

A PKI access entry configures roles in an existing PKI mount:

```yaml
pki/org-ca:
  type: pki
  roles:
    web:
      client_flag: false
      server_flag: true
      ttl: 7776000
      organization: [MyOrg]
      country: [US]
      locality: [LA]
      allowed_domains: [example.com, dev.example.com]
      allow_bare_domains: false
      allow_glob_domains: true
      key_usage: [DigitalSignature, KeyEncipherment]
      ext_key_usage: []
      access:
        static:
          - ldap.groups.CertificateAdministrators
```

Role fields and defaults:

| Access field | Default | Rendered behavior |
| --- | --- | --- |
| `client_flag` | `true` | Enables client-certificate use. |
| `server_flag` | `false` | Enables server-certificate use. |
| `ttl` | `600` | Rendered as both `ttl` and `maxTtl`; there is no separate PKI maximum-TTL input. Keep it numeric in YAML. |
| `organization` | `[]` | Certificate subject organizations. |
| `country` | `[]` | Certificate subject countries. |
| `locality` | `[]` | Certificate subject localities. |
| `allowed_domains` | `[]` | Literal allowed domains. |
| `templated_common_name` | `[]` | Names resolved through operational `templatedCommonNames` and appended to allowed domains. |
| `key_usage` | `DigitalSignature`, `KeyAgreement`, `KeyEncipherment` | X.509 key usages. |
| `ext_key_usage` | `[]` | X.509 extended key usages. |
| `allow_bare_domains` | `false` | Controls bare-domain issuance. |
| `allow_glob_domains` | `false` | Controls glob-domain matching. |

Operational mount settings:

```yaml
_vaultYaml:
  secrets:
    pki:
      mounts:
        pki/org-ca:
          issuerRef: default
          templatedCommonNames:
            email: '{{identity.entity.name}}@example.com'
```

| Setting | Default | Meaning |
| --- | --- | --- |
| `issuerRef` | `default` | Existing issuer reference used by every role in this mount. |
| `templatedCommonNames.<name>` | None | Vault template appended to `allowedDomains` when the access role lists `<name>` in `templated_common_name`. |

An unknown `templated_common_name` fails rendering. If at least one is configured, `allowedDomainsTemplate` is enabled.

Each role also receives a policy allowing `read` and `update` on `<mount>/issue/<role>` and `<mount>/sign/<role>`, plus read/list access to the relevant role-discovery paths.

## Kubernetes secrets engines

`type: kubernetes` means roles in an existing Vault Kubernetes **secrets engine** that generates Kubernetes credentials. It is distinct from static `kubernetes.<namespace>.<serviceaccount>` principals, which use an existing Kubernetes **auth method**.

```yaml
staging/cluster01:
  type: kubernetes
  roles:
    deployer:
      namespaces: [application, playground]
      ttl: 600
      ttl_max: 3600
      access:
        static:
          - ldap.groups.Developers
```

Role fields and defaults:

| Access field | Default | Rendered behavior |
| --- | --- | --- |
| `namespaces` | `[]` | Sorted before being supplied as `allowedKubernetesNamespaces`. |
| `ttl` | `600` | Generated token default TTL. |
| `ttl_max` | `3600` | Generated token maximum TTL. |

If `namespaces` contains `"*"`, the generated Kubernetes role type is `ClusterRole`; otherwise it is `Role`.

Every access role requires a same-named operational role definition:

```yaml
_vaultYaml:
  secrets:
    kubernetes:
      mounts:
        staging/cluster01:
          roleDefinitions:
            deployer: |
              rules:
                - apiGroups: ["apps"]
                  resources: [deployments]
                  verbs: [get, list, create, update, patch]
          nameTemplate: '{{.DisplayName}}-{{.RoleName}}-{{unix_time}}s'
          labels:
            managed_by: vault
```

The role-definition value must be valid YAML with a non-empty top-level `rules` field. A missing definition, invalid YAML, or absent `rules` fails rendering. It is encoded as JSON into the provider's `generatedRoleRules` field.

Operational `labels` are merged with:

```yaml
provisioned_for: ""
generated_from: <mount-path>/<role-name>
```

User-supplied keys take precedence. `nameTemplate` is passed to the Vault Kubernetes secrets backend role as supplied.

Each role receives a policy allowing `read` and `update` on `<mount>/creds/<role>`. Its `kubernetes_namespace` parameter is constrained to the role's `namespaces` list.

## SSH secrets engines

An SSH access entry configures CA roles in an existing SSH secrets-engine mount:

```yaml
staging/vms:
  type: ssh
  roles:
    developer:
      ttl: 60
      ttl_max: 600
      extensions:
        - permit-pty
        - permit-port-forwarding
      access:
        static:
          - ldap.groups.Developers
```

Role fields and defaults:

| Access field | Default | Rendered behavior |
| --- | --- | --- |
| `ttl` | `60` | SSH certificate TTL. |
| `ttl_max` | `600` | Maximum SSH certificate TTL. |
| `extensions` | `[permit-pty]` | Comma-joined into `allowedExtensions`; each extension is also enabled with an empty value in `defaultExtensions`. |

Operational mount settings provide Vault identity templates for users:

```yaml
_vaultYaml:
  secrets:
    ssh:
      mounts:
        staging/vms:
          allowedUsers: '{{identity.entity.name}}'
          defaultUser: '{{identity.entity.name}}'
```

The chart always renders CA key type, user certificates enabled, and template processing enabled for both `allowedUsers` and `defaultUser`.

Each role receives a policy allowing `update` on `<mount>/sign/<role>` and `list`/`read` on `<mount>/roles/*`.

## Ad-hoc policies

Ad-hoc policies provide arbitrary Vault policy HCL without tying it to a secrets-engine role.

The portable access document declares policy roles and their recipients:

```yaml
adhoc:
  type: vault
  roles:
    secrets-personal:
      access:
        static:
          - ldap.groups.Everyone

    secrets-group:
      for_each: true
      access:
        static:
          - ldap.groups.Administrators
          - ldap.groups.Everyone
```

The operational values provide the actual HCL templates and template parameters:

```yaml
_vaultYaml:
  adhoc:
    parameters:
      kvPath: kvv2
      ldapAccessor: auth_ldap_01234567
    policyTemplates:
      secrets-personal: |
        path "${kvPath}/data/vaults/personal/{{identity.entity.aliases.${ldapAccessor}.metadata.name}}/*" {
          capabilities = ["create", "update", "patch", "read", "delete"]
        }

      secrets-group: |
        path "${kvPath}/data/vaults/teams/${accessName}/*" {
          capabilities = ["create", "update", "patch", "read", "delete"]
        }
```

### Template lookup

Each `adhoc.roles.<role-name>` requires a matching multiline string at:

```text
_vaultYaml.adhoc.policyTemplates.<role-name>
```

The role name is the lookup key; the chart does not read `roles/vault/*.hcl` from the filesystem. A missing or empty matching template fails rendering.

### Explicit template parameters

Parameters are literal `${name}` placeholders in the HCL string.

| Placeholder | Source | Availability |
| --- | --- | --- |
| `${kvPath}` | `_vaultYaml.adhoc.parameters.kvPath` | Available when explicitly configured. |
| `${ldapAccessor}` | `_vaultYaml.adhoc.parameters.ldapAccessor` | Available when explicitly configured. |
| `${<customName>}` | `_vaultYaml.adhoc.parameters.<customName>` | Any user-defined parameter is supported. Values are converted to strings. |
| `${accessName}` | Derived by the chart | Reserved. Primarily intended for `for_each: true`; it is an empty string for shared policies. |

`kvPath` and `ldapAccessor` are examples provided by the default values, not hard-coded special cases. All keys below `_vaultYaml.adhoc.parameters` are handled uniformly except `accessName`.

Do not define `_vaultYaml.adhoc.parameters.accessName`; rendering fails because the chart owns it.

Substitution is a literal Helm `replace`, not Go-template, Terraform-template, shell, or HCL evaluation:

- Write placeholders exactly as `${parameterName}`; no whitespace or expression syntax is supported.
- Every occurrence of a configured placeholder is replaced.
- Values are converted to strings before replacement.
- `${accessName}` is replaced after the configured parameters.
- Vault policy templates such as `{{identity.entity.name}}` are preserved for Vault to evaluate later.
- Unknown or misspelled `${...}` placeholders are currently left unchanged; the chart does not reject them.
- Replacement is textual and does not HCL-escape parameter values. Treat parameter values as trusted policy source and quote/structure the template appropriately.

### Shared mode: `for_each` omitted or false

With `for_each` omitted or `false`, one policy is rendered for the role regardless of the number of static principals:

```text
vault-<role-name>-adhoc
```

For example, `secrets-personal` creates:

```text
vault-secrets-personal-adhoc
```

The same policy is attached to every principal in `access.static`. `${accessName}` is replaced with an empty string in this mode.

### Per-principal mode: `for_each: true`

With `for_each: true`, the chart renders one policy for each item in `access.static` and attaches only that policy to that principal.

For each principal, the chart parses the principal grammar, removes any `::` options, selects its semantic identity, joins multi-part identities with `-`, and replaces every remaining non-alphanumeric run with `-`. Leading and trailing hyphens are removed; letter case is preserved.

| Principal | `${accessName}` | Policy name for role `secrets-group` |
| --- | --- | --- |
| `ldap.groups.Administrators` | `Administrators` | `vault-secrets-group-adhoc-Administrators` |
| `ldap.groups.Platform.Administrators` | `Platform-Administrators` | `vault-secrets-group-adhoc-Platform-Administrators` |
| `identity.entity_name.Build.Bot` | `Build-Bot` | `vault-secrets-group-adhoc-Build-Bot` |
| `identity.group_id.2a91...` | `2a91` | `vault-secrets-group-adhoc-2a91` |
| `kubernetes.default.external-secrets` | `default-external-secrets` | `vault-secrets-group-adhoc-default-external-secrets` |
| `cert.test@example.com` | `test-example-com` | `vault-secrets-group-adhoc-test-example-com` |

The generated external Vault policy name is:

```text
vault-<role-name>-adhoc-<accessName>
```

The policy is rendered with `${accessName}` replaced by that value. This enables per-principal paths such as:

```hcl
path "kvv2/data/vaults/teams/Administrators/*" {
  capabilities = ["read"]
}
```

Principal-specific extraction is:

- LDAP users/groups: everything after `ldap.users.` or `ldap.groups.`.
- Identity entities/groups: everything after `identity.entity_id.`, `identity.entity_name.`, `identity.group_id.`, or `identity.group_name.`.
- Kubernetes: both `<namespace>` and `<serviceaccount>`.
- Certificate: the complete common name after `cert.`.
- Userpass: the complete username after `userpass.`.

Identity name extraction affects only `accessName`. Terraform still resolves `identity.entity_name.*` and `identity.group_name.*` to their Vault IDs for policy attachment; Crossplane continues to warn because it supports identity attachment by ID only.

Important constraints:

- Unsupported or malformed principals fail Helm rendering when used by an ad-hoc `for_each` role.
- Different principals can normalize to the same `accessName`; such entries collide for the same role. Avoid aliases that differ only by punctuation.
- An empty `access.static` list produces no policy in `for_each` mode.

Use short, collision-free principal names when a role enables `for_each`, and inspect the rendered policy names and HCL before installation.

## Static principals

Policies from every engine and ad-hoc role are aggregated by the complete principal string. One binding resource is then rendered per supported principal with a sorted, deduplicated policy list.

Principal values may contain dots where noted below.

| Principal | Required operational setting | Rendered result |
| --- | --- | --- |
| `ldap.users.<username>` | `auth.ldap.enabled: true` | `ldap.vault.upbound.io/v1alpha1` `AuthBackendUser` in the configured backend. Everything after `ldap.users.` is preserved, including dots. |
| `ldap.groups.<groupname>` | `auth.ldap.enabled: true` | `ldap.vault.upbound.io/v1alpha1` `AuthBackendGroup` in the configured backend. Everything after `ldap.groups.` is preserved, including dots. |
| `identity.entity_id.<id>` | `auth.identity.enabled: true` | Additive `EntityPolicies` attachment (`exclusive: false`) by immutable ID. Everything after the prefix is preserved. |
| `identity.group_id.<id>` | `auth.identity.enabled: true` | Additive `GroupPolicies` attachment (`exclusive: false`) by immutable ID. Everything after the prefix is preserved. |
| `cert.<common-name>` | `auth.cert.enabled: true` | Certificate `AuthBackendRole` in the configured backend. |
| `kubernetes.<namespace>.<serviceaccount>` | `auth.kubernetes.enabled: true` | Kubernetes `AuthBackendRole` named `<namespace>-<serviceaccount>` in the configured auth backend. Exactly three segments are required. |

### LDAP

```yaml
_vaultYaml:
  auth:
    ldap:
      enabled: true
      backend: ldap
```

The backend must already exist. LDAP mappings set the policy list represented by the rendered `AuthBackendUser` or `AuthBackendGroup` resource.

### Identity names versus IDs

The Terraform implementation supports identity lookup by name, but this chart intentionally supports Crossplane identity attachments by ID only:

```text
identity.entity_id.<entity-id>
identity.group_id.<group-id>
```

Name forms are not rendered and appear in the warnings ConfigMap:

```text
identity.entity_name.<entity-name>
identity.group_name.<group-name>
```

Helm cannot query Vault during deterministic rendering, and `provider-vault` does not expose a declarative name-to-ID lookup that can feed `EntityPolicies` or `GroupPolicies`.

Resolve IDs before deployment:

```bash
vault read -format=json identity/entity/name/my-entity
vault read -format=json identity/group/name/my-group
```

Use the returned `data.id`:

```yaml
access:
  static:
    - identity.entity_id.8d8c0000-0000-0000-0000-000000000000
    - identity.group_id.2a910000-0000-0000-0000-000000000000
```

Identity attachments are additive (`exclusive: false`), so the chart does not intentionally remove policies assigned by another owner.

### Certificate authentication

Certificate principals are opt-in:

```yaml
_vaultYaml:
  auth:
    cert:
      enabled: true
      backend: cert
      trustedCertificate: |
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
```

The auth mount and trusted public CA certificate must already be available. When enabled, `trustedCertificate` is required. The common name is preserved in `allowedNames`; `@` is replaced with `-` in the external certificate role name.

The Terraform `cert.*::ip_bind=true` DNS-to-CIDR expansion is not implemented. The chart does not populate `tokenBoundCidrs` from DNS.

### Kubernetes authentication

Static Kubernetes principals are also opt-in:

```yaml
_vaultYaml:
  auth:
    kubernetes:
      enabled: true
      backend: kubernetes/cluster01
```

For:

```text
kubernetes.default.external-secrets
```

the chart creates a role named `default-external-secrets`, bound to ServiceAccount `external-secrets` in namespace `default`, with all policies collected for that principal.

The Kubernetes auth method itself and its connection to a Kubernetes API server are prerequisites.

### Disabled or unsupported principals

If a principal is unsupported, malformed for its renderer, or its auth integration is disabled, no binding resource is created. The chart adds this to the render-warnings ConfigMap instead of failing the release.

This includes, among others:

- `identity.entity_name.*` and `identity.group_name.*`.
- `userpass.*`.
- JWT/OIDC forms.
- Malformed Kubernetes principals.
- Otherwise supported principal forms whose `_vaultYaml.auth.<type>.enabled` value is false.

Treat warnings as deployment findings, not informational noise: the corresponding principal did not receive the policy through this chart.

## Conditional access and render warnings

GatePlane Policy Gate reconciliation is not implemented in this chart release. `_vaultYaml.conditionalAccess.enabled` and `endpointPath` are present as reserved operational settings but do not currently cause conditional resources to be rendered.

For PKI, Kubernetes, and SSH roles containing `access.conditional`, the chart renders the engine role and its normal policy and records a warning similar to:

```text
<mount>/<role> uses conditional access; GatePlane endpoint reconciliation is not enabled in this release
```

It does not attach that policy to conditional requestors or approvers. Static access on the same role continues to work.

Warnings are emitted in a ConfigMap named from `vault-yaml-render-warnings` with the chart's stable hash suffix. Find and inspect it with:

```bash
kubectl get configmap \
  -l vault-yaml.gateplane.io/type=warnings \
  -o yaml
```

No warnings ConfigMap is rendered when the warning list is empty.

## Lifecycle and ownership

Every managed resource receives the same Crossplane lifecycle settings:

```yaml
_vaultYaml:
  lifecycle:
    deletionPolicy: Orphan
    managementPolicies:
      - Create
      - Observe
      - Update
      - LateInitialize
```

These defaults intentionally omit `Delete`. Deleting a managed resource or uninstalling the Helm release therefore leaves its external Vault object orphaned by default.

To permit external deletion explicitly:

```yaml
_vaultYaml:
  lifecycle:
    deletionPolicy: Delete
    managementPolicies:
      - Create
      - Observe
      - Update
      - LateInitialize
      - Delete
```

Changing ownership or deletion behavior can remove security configuration. Review it independently from ordinary role changes.

The chart does not implement automatic import/adoption annotations or a Terraform-to-Crossplane state handoff. Before migrating an existing object, verify the provider's external-name/import requirements and ensure Terraform has relinquished ownership without destroying the object.

## Rendering and validation

The chart validates that:

- `accessFile` is present and non-empty.
- `accessFile` parses as YAML.
- Every top-level entry is an object.
- Every top-level entry defines `type`.
- `type` is one of `pki`, `kubernetes`, `ssh`, or `vault`.
- Every top-level entry defines `roles`.
- Every PKI/Kubernetes/SSH access path has matching operational mount settings.
- Referenced PKI common-name templates exist.
- Referenced Kubernetes role definitions exist, parse as YAML, and contain `rules`.
- Referenced ad-hoc policy templates exist.
- `adhoc.parameters.accessName` is not user-defined.
- A trusted certificate is present when certificate-auth rendering is actually required.

The chart's values schema rejects unknown top-level Helm values but intentionally treats `_vaultYaml` as an open object. It does not fully validate every nested role field, principal grammar, HCL policy, or provider CRD field before rendering.

Recommended workflow:

1. Validate the access document against the repository's `schema.json`.
2. Run `helm lint` and `helm template`.
3. Inspect every generated policy body, external Vault name, and render warning.
4. Validate rendered manifests against the installed `provider-vault` CRDs.
5. Install the release.
6. Wait for every managed resource to report `Ready=True` and `Synced=True`.
7. Test both permitted and denied Vault operations.

## Current limitations

- GatePlane conditional-access resources are not reconciled. PKI, Kubernetes, and SSH conditional blocks produce render warnings.
- Ad-hoc conditional access is not reconciled; only `access.static` drives ad-hoc bindings.
- Identity attachments by name are Terraform-only. Crossplane requires `identity.entity_id` or `identity.group_id`.
- Certificate-auth roles require `_vaultYaml.auth.cert.enabled: true` and an inline trusted public CA certificate in operational values.
- `cert.*::ip_bind=true` DNS-to-CIDR expansion is unavailable.
- Existing LDAP, certificate, and Kubernetes auth backends are referenced but never created.
- `userpass`, JWT, and OIDC principals are not rendered.
- Unsupported, malformed, or disabled principal integrations warn rather than fail Helm rendering.
- Unknown placeholders in ad-hoc HCL templates are left literal rather than rejected.
- `for_each` normalizes semantic principal names but does not detect collisions where different principals normalize to the same `accessName`.
- `type: vault` is operational only under the exact top-level key `adhoc`.
- The chart does not create reconciliation dependencies on prerequisite Vault mounts or CAs; Crossplane retries until prerequisites are available.
- Helm success is not proof of Crossplane or Vault reconciliation.
