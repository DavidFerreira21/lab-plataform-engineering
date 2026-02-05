{{- define "app-template.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "app-template.serviceName" -}}
{{- if .Values.service.name -}}
{{- .Values.service.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-svc" (include "app-template.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
