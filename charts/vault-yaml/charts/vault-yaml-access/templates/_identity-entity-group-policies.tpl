{{- define "vault-yaml-access.identityEntityPolicies" -}}
{{- $parts := .parts -}}
{{- $s := .settings -}}
{{- if and (not .handled) (ge (len $parts) 3) (eq (index $parts 0) "identity") (eq (index $parts 1) "entity_id") $s.auth.identity.enabled }}
{{- $_ := set . "handled" true -}}
{{- $id := join "." (slice $parts 2) }}
---
apiVersion: identity.vault.upbound.io/v1alpha1
kind: EntityPolicies
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "identity-entity-%s" $id)) }}
spec:
  forProvider:
    entityId: {{ $id | quote }}
    exclusive: false
    policies:
{{ toYaml (sortAlpha .policies) | indent 6 }}
{{ include "vault-yaml.lifecycle" (dict "root" .root) | indent 2 }}
{{- end }}
{{- end -}}

{{- define "vault-yaml-access.identityGroupPolicies" -}}
{{- $parts := .parts -}}
{{- $s := .settings -}}
{{- if and (not .handled) (ge (len $parts) 3) (eq (index $parts 0) "identity") (eq (index $parts 1) "group_id") $s.auth.identity.enabled }}
{{- $_ := set . "handled" true -}}
{{- $id := join "." (slice $parts 2) }}
---
apiVersion: identity.vault.upbound.io/v1alpha1
kind: GroupPolicies
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "identity-group-%s" $id)) }}
spec:
  forProvider:
    groupId: {{ $id | quote }}
    exclusive: false
    policies:
{{ toYaml (sortAlpha .policies) | indent 6 }}
{{ include "vault-yaml.lifecycle" (dict "root" .root) | indent 2 }}
{{- end }}
{{- end -}}
