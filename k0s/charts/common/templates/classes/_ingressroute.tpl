{{/*
This template serves as a blueprint for all IngressRoute objects that are created
within the common library.
*/}}
{{- define "common.classes.ingressroute" -}}
  {{- $fullName := include "common.names.fullname" . -}}
  {{- $ingressRouteName := $fullName -}}
  {{- $values := .Values.ingressRoute -}}

  {{- if hasKey . "ObjectValues" -}}
    {{- with .ObjectValues.ingressRoute -}}
      {{- $values = . -}}
    {{- end -}}
  {{ end -}}

  {{- if and (hasKey $values "nameOverride") $values.nameOverride -}}
    {{- $ingressRouteName = printf "%v-%v" $ingressRouteName $values.nameOverride -}}
  {{- end -}}

  {{- $primaryService := get .Values.service (include "common.service.primary" .) -}}
  {{- $defaultServiceName := $fullName -}}
  {{- if and (hasKey $primaryService "nameOverride") $primaryService.nameOverride -}}
    {{- $defaultServiceName = printf "%v-%v" $defaultServiceName $primaryService.nameOverride -}}
  {{- end -}}
  {{- $defaultServicePort := get $primaryService.ports (include "common.classes.service.ports.primary" (dict "values" $primaryService)) -}}
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: {{ $ingressRouteName }}
  {{- with (merge ($values.labels | default dict) (include "common.labels" $ | fromYaml)) }}
  labels: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with (merge ($values.annotations | default dict) (include "common.annotations" $ | fromYaml)) }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with $values.entryPoints }}
  entryPoints:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  routes:
    {{- range $values.routes }}
    - match: {{ tpl .match $ }}
      kind: {{ default "Rule" .kind }}
      {{- if or .middlewares $values.authentik }}
      middlewares:
        {{- if $values.authentik }}
        - name: authentik
          namespace: traefik
        {{- end }}
        {{- range .middlewares }}
        - name: {{ .name }}
          {{- if .namespace }}
          namespace: {{ .namespace }}
          {{- end }}
        {{- end }}
      {{- end }}
      services:
        {{- if .services }}
        {{- range .services }}
        - name: {{ default $defaultServiceName .name }}
          port: {{ default $defaultServicePort.port .port }}
          {{- if .scheme }}
          scheme: {{ .scheme }}
          {{- end }}
          {{- if .passHostHeader }}
          passHostHeader: {{ .passHostHeader }}
          {{- end }}
        {{- end }}
        {{- else }}
        - name: {{ $defaultServiceName }}
          port: {{ $defaultServicePort.port }}
        {{- end }}
    {{- end }}
  {{- if $values.tls }}
  tls:
    {{- if eq (kindOf $values.tls) "map" }}
    {{- with $values.tls.secretName }}
    secretName: {{ . }}
    {{- end }}
    {{- with $values.tls.options }}
    options:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with $values.tls.certResolver }}
    certResolver: {{ . }}
    {{- end }}
    {{- with $values.tls.domains }}
    domains:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- else }}
    {}
    {{- end }}
  {{- end }}
{{- end }}
