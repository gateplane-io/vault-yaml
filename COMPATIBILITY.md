# Versioning and compatibility

Crossplane (Helm chart) and Terraform are alternative reconcilers. Never use both to manage the
same external Vault or OpenBao objects concurrently.

## Version scopes

| Component | Version source | Scope |
| --- | --- | --- |
| Helm chart | `charts/vault-yaml/Chart.yaml` `version` | Chart templates, generated Crossplane resources, and `_vaultYaml` operational values. |
| Access contract | `ACCESS-CONTRACT-VERSION` | Portable `accessFile`, `schema.json`, and behavior shared by reconcilers. |
| Terraform | `terraform/<version>` Git tags | Terraform resources, module interfaces, state addresses, and provider behavior. |

The Helm chart's `appVersion` must equal `ACCESS-CONTRACT-VERSION`. Embedded
Helm library charts are implementation details and use the same version as the
parent chart.

## Current compatibility

| Helm chart | Access contract | provider-vault | Kubernetes |
| --- | --- | --- | --- |
| `0.2.x` | `0.1.0` | `4.x` | `>=1.28.0-0` |

## Release tags

- Helm chart: `chart/<semver>`, for example `chart/0.2.0`.
- Terraform: `terraform/<semver>`, for example `terraform/0.1.0`.
- Access contract: `contract/<semver>`, only when the portable contract changes.

## Semantic versioning

### Helm chart

- Patch: backward-compatible chart fixes.
- Minor: backward-compatible features; before `1.0.0`, breaking changes also
  increment the minor version.
- Major: breaking changes after `1.0.0`.

### Access contract

- Patch: clarifications or fixes preserving accepted input and behavior.
- Minor: backward-compatible fields or capabilities.
- Major: changes that invalidate or reinterpret existing access documents.

A chart-only `_vaultYaml` change does not increment the access-contract version.
