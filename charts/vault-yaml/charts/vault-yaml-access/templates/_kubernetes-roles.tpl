{{- define "vault-yaml-access.kubernetesRole" -}}
{{- $parts := .parts -}}
{{- $s := .settings -}}
{{- if and (not .handled) (eq (len $parts) 3) (eq (index $parts 0) "kubernetes") $s.auth.kubernetes.enabled }}
{{- $_ := set . "handled" true -}}
{{- $namespace := index $parts 1 -}}
{{- $serviceAccount := index $parts 2 -}}
{{- $roleName := printf "%s-%s" $namespace $serviceAccount -}}
---
apiVersion: kubernetes.vault.upbound.io/v1alpha1
kind: AuthBackendRole
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "kubernetes-auth-role-%s" $roleName)) }}
  labels:
{{ include "vault-yaml.labels" (dict "root" .root "type" "kubernetes-auth-role" "path" $s.auth.kubernetes.backend) | indent 4 }}
  annotations:
{{ include "vault-yaml.annotations" (dict "path" $s.auth.kubernetes.backend "role" $roleName) | indent 4 }}
spec:
  forProvider:
    backend: {{ $s.auth.kubernetes.backend | quote }}
    roleName: {{ $roleName | quote }}
    boundServiceAccountNames:
      - {{ $serviceAccount | quote }}
    boundServiceAccountNamespaces:
      - {{ $namespace | quote }}
    tokenPolicies:
{{ toYaml (sortAlpha .policies) | indent 6 }}
{{ include "vault-yaml.lifecycle" (dict "root" .root) | indent 2 }}
{{- end }}
{{- end -}}
