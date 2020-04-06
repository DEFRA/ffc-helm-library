{{/*
Common labels
*/}}
{{- define "ffc-helm-library.labels" -}}
app: {{ quote .Values.namespace }}
app.kubernetes.io/name: {{ quote .Values.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ quote .Values.labels.version | default "1.0.0" }}
app.kubernetes.io/component: {{ quote .Values.labels.component | default "service" }}
app.kubernetes.io/part-of: {{ quote .Values.namespace }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
environment: {{ quote .Values.environment }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "ffc-helm-library.selectorLabels" -}}
app.kubernetes.io/name: {{ quote .Values.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Required value message
*/}}
{{- define "ffc-helm-library.requiredMsg.tpl" -}}
{{- $name := (index . 1) -}}
{{- $value := (index . 2) -}}
{{- required (printf "No value found for '%s' in ffc-helm-library template" $name) $value -}}
{{- end -}}

