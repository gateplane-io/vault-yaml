{{- define "vault-yaml-kubernetes.role" -}}
{{- $root := .root -}}
{{- $mountSettings := .mountSettings -}}
{{- $path := .path -}}
{{- $roleName := .roleName -}}
{{- $role := .role -}}
{{- $namespaces := default (list) $role.namespaces }}
---
apiVersion: kubernetes.vault.upbound.io/v1alpha1
kind: SecretBackendRole
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "kubernetes-role-%s-%s" $path $roleName)) }}
  labels:
{{ include "vault-yaml.labels" (dict "root" $root "type" "kubernetes-role" "path" $path) | indent 4 }}
  annotations:
{{ include "vault-yaml.annotations" (dict "path" $path "role" $roleName) | indent 4 }}
spec:
  forProvider:
    backend: {{ $path | quote }}
    name: {{ $roleName | quote }}
    allowedKubernetesNamespaces:
{{ toYaml (sortAlpha $namespaces) | indent 6 }}
    tokenDefaultTtl: {{ default 600 $role.ttl }}
    tokenMaxTtl: {{ default 3600 $role.ttl_max }}
    kubernetesRoleType: {{ ternary "ClusterRole" "Role" (has "*" $namespaces) | quote }}
    generatedRoleRules: {{ include "vault-yaml.roleRules" (dict "mountSettings" $mountSettings "path" $path "role" $roleName) | quote }}
    extraLabels:
{{ toYaml (merge (dict "provisioned_for" "" "generated_from" (printf "%s/%s" $path $roleName)) (default dict $mountSettings.labels)) | indent 6 }}
    nameTemplate: {{ $mountSettings.nameTemplate | quote }}
{{ include "vault-yaml.lifecycle" (dict "root" $root) | indent 2 }}
{{ end -}}
