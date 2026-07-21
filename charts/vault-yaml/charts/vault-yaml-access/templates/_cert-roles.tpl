{{- define "vault-yaml-access.certRole" -}}
{{- $parts := .parts -}}
{{- $s := .settings -}}
{{- if and (not .handled) (ge (len $parts) 2) (eq (index $parts 0) "cert") $s.auth.cert.enabled }}
{{- $_ := set . "handled" true -}}
{{- $certParts := splitList "::" (trimPrefix "cert." .principal) -}}
{{- $commonName := index $certParts 0 }}
---
apiVersion: cert.vault.upbound.io/v1alpha1
kind: AuthBackendRole
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "cert-role-%s" $commonName)) }}
spec:
  forProvider:
    backend: {{ $s.auth.cert.backend | quote }}
    name: {{ replace "@" "-" $commonName | quote }}
    certificate: {{ required "_vaultYaml.auth.cert.trustedCertificate is required when cert auth is enabled" $s.auth.cert.trustedCertificate | quote }}
    allowedNames: [{{ $commonName | quote }}]
    tokenPolicies:
{{ toYaml (sortAlpha .policies) | indent 6 }}
{{ include "vault-yaml.lifecycle" (dict "root" .root) | indent 2 }}
{{- end }}
{{- end -}}
