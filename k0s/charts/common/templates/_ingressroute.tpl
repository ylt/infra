{{/* Renders the IngressRoute objects required by the chart */}}
{{- define "common.ingressRoute" -}}
  {{- /* Generate named ingressRoutes as required */ -}}
  {{- range $name, $ingressRoute := .Values.ingressRoute }}
    {{- if $ingressRoute.enabled -}}
      {{- $ingressRouteValues := $ingressRoute -}}

      {{/* set defaults */}}
      {{- if and (not $ingressRouteValues.nameOverride) (ne $name (include "common.ingressRoute.primary" $)) -}}
        {{- $_ := set $ingressRouteValues "nameOverride" $name -}}
      {{- end -}}

      {{- $_ := set $ "ObjectValues" (dict "ingressRoute" $ingressRouteValues) -}}
      {{- include "common.classes.ingressroute" $ }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Return the name of the primary ingressRoute object */}}
{{- define "common.ingressRoute.primary" -}}
  {{- $enabledIngressRoutes := dict -}}
  {{- range $name, $ingressRoute := .Values.ingressRoute -}}
    {{- if $ingressRoute.enabled -}}
      {{- $_ := set $enabledIngressRoutes $name . -}}
    {{- end -}}
  {{- end -}}

  {{- $result := "" -}}
  {{- range $name, $ingressRoute := $enabledIngressRoutes -}}
    {{- if and (hasKey $ingressRoute "primary") $ingressRoute.primary -}}
      {{- $result = $name -}}
    {{- end -}}
  {{- end -}}

  {{- if not $result -}}
    {{- $result = keys $enabledIngressRoutes | first -}}
  {{- end -}}
  {{- $result -}}
{{- end -}}
