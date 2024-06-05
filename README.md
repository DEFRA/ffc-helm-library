---
title: ADP Platform Helm Library Chart
summary: A Helm library chart that captures general configuration for the ADP Kubernetes platform.
uri: https://defra.github.io/adp-documentation/Developer-Reference/Infrastructure/ASO%20Helm%20Library%20Chart/
authors:
    - Ganesh Shivajee Ghadge
    - Jeevan Kuduva Ravindran
date: 2024-04-04
---

# ADP Platform Helm Library Chart

A Helm library chart that captures general configuration for the ADP Kubernetes platform. It can be used by any microservice Helm chart to import K8s object templates configured to run on the ADP platform.

## Including the library chart

In your microservice Helm chart:
  * Update `Chart.yaml` to `apiVersion: v2`.
  * Add the library chart under `dependencies` and choose the version you want (example below). Version number can include `~` or `^` to pick up latest PATCH and MINOR versions respectively.
  * Issue the following commands to add the repo that contains the library chart, update the repo, then update dependencies in your Helm chart:

```
helm repo add adp https://raw.githubusercontent.com/defra/adp-helm-repository/master/
helm repo update
helm dependency update <helm_chart_location>
```

An example ADP microservice `Chart.yaml`:

```
apiVersion: v2
description: A Helm chart to deploy a microservice to the ADP Azure Kubernetes platform
name: adp-microservice
version: 1.0.0
dependencies:
- name: adp-helm-library
  version: ^1.0.0
  repository: https://raw.githubusercontent.com/defra/adp-helm-repository/master/
```

## Using the K8s object templates

First, follow [the instructions](#including-the-library-chart) for including the ADP Helm library chart.

The ADP Helm library chart has been configured using the conventions described in the [Helm library chart documentation](https://helm.sh/docs/topics/library_charts/). The K8s object templates provide settings shared by all objects of that type, which can be augmented with extra settings from the parent (ADP microservice) chart. The library object templates will merge the library and parent templates. In the case where settings are defined in both the library and parent chart, the parent chart settings will take precedence, so library chart settings can be overridden. The library object templates will expect values to be set in the parent `.values.yaml`. Any required values (defined for each template below) that are not provided will result in an error message when processing the template (`helm install`, `helm upgrade`, `helm template`).

The general strategy for using one of the library templates in the parent microservice Helm chart is to create a template for the K8s object formateted as so:

```
{{- include "adp-helm-library.secret" (list . "adp-microservice.secret") -}}
{{- define "adp-microservice.secret" -}}
# Microservice specific configuration in here
{{- end -}}
```

This example would be for `template/secret.yaml` in the `adp-microservice` Helm chart. The initial `include` statement can be wrapped in an `if` statement if you only wish to create the K8s object based on a condition. E.g., only create the secret is a `pr` value has been set in `values.yaml`:

```
{{- if .Values.pr }}
{{- include "adp-helm-library.secret" (list . "adp-microservice.secret") -}}
{{- end }}
{{- define "adp-microservice.secret" -}}
# Microservice specific configuration in here
{{- end -}}
```


### All template required values

All the K8s object templates in the library require the following values to be set in the parent microservice Helm chart's `values.yaml`:

```
name: <string>
namespace: <string>
```

### Cluster IP service template

* Template file: `_cluster-ip-service.yaml`
* Template name: `adp-helm-library.cluster-ip-service`

A K8s `Service` object of type `ClusterIP`.

A basic usage of this object template would involve the creation of `templates/cluster-ip-service.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.cluster-ip-service" (list . "adp-microservice.service") -}}
{{- define "adp-microservice.service" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):
```
container:
  port: <integer>
```

### Container template

* Template file: `_container.yaml`
* Template name: `adp-helm-library.container`

A template for the container definition to be used within a K8s `Deployment` object.

A basic usage of this object template would involve the creation of `templates/_container.yaml` in the parent Helm chart (e.g. `adp-microservice`). Note the `_` in the name. This template is part of the `Deployment` object definition and will be used in conjunction the `_deployment.yaml` template ([see below](#deployment-template)). As a minimum `templates/_container.yaml` would define environment variables and may also include liveness/readiness probes when applicable e.g.:

```
{{- define "adp-microservice.container" -}}
env: <list>
livenessProbe: <map>
readinessProbe: <map>
{{- end -}}
```

The liveness and readiness probes could take advantage of the helper templates for [http GET probe](#http-get-probe) and [exec probe](#exec-probe) defined within the library chart and described below.

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
image: <string>
container: {}
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to select the required CPU and Memory for a container:

```
container:
  memCpuTier: <string S|M|L|XL|XXL|CUSTOM>
  requestMemory: <string - REQUIRED if memCpuTier is CUSTOM>
  requestCpu: <string - REQUIRED if memCpuTier is CUSTOM>
  limitMemory: <string - REQUIRED if memCpuTier is CUSTOM>
  limitCpu: <string - REQUIRED if memCpuTier is CUSTOM>
```

Please see memCpuTier values in the below table:

| TIER   | CPU-REQUEST | CPU-LIMIT | MEMORY-REQUEST | MEMORY-LIMIT |
| ------ | ----------- | --------- | -------------- | ------------ |
| S      | 50m         | 50m       | 50Mi           | 50Mi         |
| M      | 100m        | 100m      | 100Mi          | 100Mi        |
| L      | 150m        | 150m      | 150Mi          | 150Mi        |
| XL     | 200m        | 200m      | 200Mi          | 200Mi        |
| XXL    | 300m        | 600m      | 300Mi          | 600Mi        |
| CUSTOM | <?>         | <?>       | <?>            | <?>          |

NOTE: 
If you do not add a 'memCpuTier' then the Tier will default to 'M'

NOTE: 
You can also choose CUSTOM and provide your own values if the TIER sizes don't fit your requirements.
If you choose CUSTOM, requestMemory, requestCpu, limitMemory and limitCpu are required.

IMPORTANT: 
Your team namespace will be given a fixed amount of resources via ResourceQuotas.  
Once your cumulative resource request total passes the assigned quota on your namespace, all further deployments will be unsuccessful.  If you require an increase to your ResourceQuota, you will need to raise a request via the ADP team.  It's important you monitor the performance of your application and adjust pod requests and limits accordingly.  Please choose the appropriate cpu and memory tier for your application or provide custom values for your CPU and Memory requests and limits.

The following values can optionally be set in the parent chart's `values.yaml` to enable a command with arguments to run within the container or change the security context:

```
container:
  imagePullPolicy: <string>
  command: <list of strings>
  args: <list of strings>
  readOnlyRootFilesystem: <boolean>
  allowPrivilegeEscalation: <boolean>
```

### Container ConfigMap template

* Template file: `_containter-config-map.yaml`
* Template name: `adp-helm-library.containter-config-map`

A K8s `ConfigMap` object object to host non-sensitive container configuration data.

A basic usage of this object template would involve the creation of `templates/containter-config-map.yaml` in the parent Helm chart (e.g. `adp-microservice`), which should include the `data` map containing the configuration data:

```
{{- include "adp-helm-library.containter-config-map" (list . "adp-microservice.containter-config-map") -}}
{{- define "adp-microservice.containter-config-map" -}}
data:
  <key1>: <value1>
  ...
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
containerConfigMap:
  name: <string>
```

### Azure Application Configuration Service ConfigMap template

* Template file: `_azure-config-service-map.yaml`
* Template name: `adp-helm-library.azure-config-service-map`

A K8s `ConfigMap` object to host non-sensitive container configuration data read from the Azure Application Configuration Service.

A basic usage of this object template would involve the creation of `templates/azure-config-service-map.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.azure-config-service-map" . -}}
```

#### Optional values

The following value can optionally be set in the parent chart's `values.yaml`:

```
containerConfigMap:
  selectors:
    - keyFilter: <string> <e.g. App1*>
      labelFilter: <string> <e.g. Common/Shared>
  keyValues:
    keyVaults:
      refresh:
        interval: <duration> <e.g. 5m>
    refresh:
      interval: <duration> <e.g. 5m> <cannot be less than 1m if specified, default is 1m>
```

### Container Secret template

* Template file: `_containter-secret.yaml`
* Template name: `adp-helm-library.containter-secret`

A K8s `Secret` object to host sensitive data such as a password or token in a container.

A basic usage of this object template would involve the creation of `templates/containter-secret.yaml` in the parent Helm chart (e.g. `adp-microservice`), which should include the `data` map containing the sensitive data :

```
{{- include "adp-helm-library.containter-secret" (list . "adp-microservice.containter-secret") -}}
{{- define "adp-microservice.containter-secret" -}}
data:
  <key1>: <value1>
  ...
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
containerSecret:
  name: <string>
  type: <string>
```

### Deployment template

* Template file: `_deployment.yaml`
* Template name: `adp-helm-library.deployment`

A K8s `Deployment` object.

A basic usage of this object template would involve the creation of `templates/deployment.yaml` in the parent Helm chart (e.g. `adp-microservice`) that includes the template defined in `_container.yaml` template:

```
{{- include "adp-helm-library.deployment" (list . "adp-microservice.deployment") -}}
{{- define "adp-microservice.deployment" -}}
spec:
  template:
    spec:
      containers:
      - {{ include "adp-helm-library.container" (list . "adp-microservice.container") }}
{{- end -}}

```

By default, Azure workload identity is enabled in the deployment template by the addition of below label and a service account with the name of the microservice is added to the deployment. These inputs are **not required** from user and are handled by platform.

```
apiVersion: apps/v1
kind: Deployment
spec:
  ...
  template:
    spec:
      metadata:
      labels:
        azure.workload.identity/use: "true"
      serviceAccountName: "adp-microservice"
```

#### Optional values

The following value can optionally be set in the parent chart's `values.yaml` to enable the configuration of imagePullSecrets in the K8s object or change the running user:

```
deployment:
  imagePullSecret: <string>
  runAsUser: <integer>
  runAsNonRoot: <boolean>
  priorityClassName: <string>
  restartPolicy: <string>
  replicas: <integer>
  minReadySeconds: <integer>
```

The following follow is enabled by default for all services. We expect all services to use Azure Workload Identities. This flag will add 'azure.workload.identity/use' label to deployment template spec:

```
aadWorkloadIdentity: true
```

### Service account template

* Template file: `_service-account.yaml`
* Template name: `adp-helm-library.service-account`

A K8s `ServiceAccount` object.

A basic usage of this object template would involve the creation of `templates/service-account.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.service-account" (list . "adp-microservice.service-account") -}}
{{- define "adp-microservice.service-account" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
serviceAccount:
  name: <string>
```

### Ingress template

* Template file: `_ingress.yaml`
* Template name: `adp-helm-library.ingress`

A K8s `Ingress` object that can be configured for Nginx. Note: this is by default managed for the service. All services will use the Nginx Ingress Controller.

A basic Nginx `Ingress` object would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.ingress" (list . "adp-microservice.ingress") -}}
{{- define "adp-microservice.ingress" -}}
metadata:
  annotations:
    <map_of_nginx-ingress-annotations>
{{- end -}}
```
A basic ALB `Ingress` object would involve the creation of `templates/ingress-alb.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.ingress" (list . "adp-microservice.ingress-alb") -}}
{{- define "adp-microservice.ingress-alb" -}}
metadata:
  annotations:
    <map_of_alb-ingress-annotation>
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
ingress:
  class: <string>
service:
  port: <integer>
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to set the value of `host`:

```
pr: <string>
ingress:
  endpoint: <string>
ingress:
  server: <string>
```

### Azure Ingress template

* Template file: `_azure-ingress.yaml`
* Template name: `adp-helm-library.azure-ingress`

A K8s `Ingress` object that can be configured for Nginx for use in Azure.

A basic Nginx `Ingress` object would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.azure-ingress" (list . "adp-microservice.ingress") -}}
{{- define "adp-microservice.ingress" -}}
metadata:
  annotations:
    <map_of_nginx-ingress-annotations>
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
ingress:
  class: <string>
service:
  port: <integer>
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to set the value of `host`:

```
pr: <string>
ingress:
  endpoint: <string>
ingress:
  server: <string>
ingress:
  type: <string>
ingress:
  path: <string>
```

The `type` value is used to create a [mergeable ingress type](https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/mergeable-ingress-types) 
and should have the value `master` or `minion`.

### Azure Ingress template (master)

* Template file: `_azure-ingress-master.yaml`
* Template name: `adp-helm-library.azure-ingress-master`

A K8s `Ingress` object that can be configured for Nginx for use in Azure with a `master` [mergeable ingress type](https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/mergeable-ingress-types).

Although the `Azure Ingress template` can also be used to create `master` mergeable ingress types.  This template exists to support scenarios where a Helm chart needs to contain both a `master` and a `minion` resource without conflicts in value properties.

A basic Nginx `Ingress` object would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.azure-ingress-master" (list . "adp-microservice.ingress") -}}
{{- define "adp-microservice.ingress" -}}
metadata:
  annotations:
    <map_of_nginx-ingress-annotations>
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
ingress:
  class: <string>
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to set the value of `host`:

```
pr: <string>
ingress:
  endpoint: <string>
ingress:
  server: <string>
```

### Postgres service template

* Template file: `_postgres-service.yaml`
* Template name: `adp-helm-library.postgres-service`

A K8s `Service` object of type `ExternalName` configured to refer to a Postgres database hosted on a server outside of the K8s cluster

A basic usage of this object template would involve the creation of `templates/postgres-service.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.postgres-service" (list . "adp-microservice.postgres-service") -}}
{{- define "adp-microservice.postgres-service" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
postgresService:
  postgresHost: <string>
  postgresExternalName: <string>
  postgresPort: <integer>
```

### RBAC role binding template

* Template file: `_role-binding.yaml`
* Template name: `adp-helm-library.role-binding`

A K8s `RoleBinding` object used to bind a role to a user as part of RBAC configuration in the K8s cluster.

A basic usage of this object template would involve the creation of `templates/role-binding.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.role-binding" (list . "adp-microservice.role-binding") -}}
{{- define "adp-microservice.role-binding" -}}
# Microservice specific configuration in here
{{- end -}}
```

### Secret template

* Template file: `_secret.yaml`
* Template name: `adp-helm-library.secret`

A K8s `Secret` object to host sensitive data such as a password or token.

A basic usage of this object template would involve the creation of `templates/secret.yaml` in the parent Helm chart (e.g. `adp-microservice`), which should include the `data` map containing the sensitive data :

```
{{- include "adp-helm-library.secret" (list . "adp-microservice.secret") -}}
{{- define "adp-microservice.secret" -}}
data:
  <key1>: <value1>
  ...
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
secret:
  name: <string>
  type: <string>
```

### Service template

* Template file: `_service.yaml`
* Template name: `adp-helm-library.service`

A generic K8s `Service` object requiring a service type to be set.

A basic usage of this object template would involve the creation of `templates/secret.yaml` in the parent Helm chart (e.g. `adp-microservice`) containing:

```
{{- include "adp-helm-library.service" (list . "adp-microservice.service") -}}
{{- define "adp-microservice.service" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
service:
  type: <string>
```

### Horizontal Pod Autoscaler template

* Template file: `_horizontal-pod-autoscaler.yaml`
* Template name: `helm-library.horizontal-pod-autoscaler`

A k8s `HorizontalPodAutoscaler`.  

A basic usage of this object template would involve the creation of `templates/horizontal-pod-autoscaler.yaml` in the parent Helm chart (e.g. `microservice`).

```
{{- include "adp-helm-library.horizontal-pod-autoscaler" (list . "microservice.horizontal-pod-autoscaler") -}}
{{- define "microservice.horizontal-pod-autoscaler" -}}
spec:
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue
        averageValue: 100Mi
{{- end -}}

```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
deployment:
  minReplicas: <integer>
  maxReplicas: <integer>
```

### Vertical Pod Autoscaler template

* Template file: `_vertical-pod-autoscaler.yaml`
* Template name: `helm-library.vertical-pod-autoscaler`

A k8s `VerticalPodAutoscaler`.  

A basic usage of this object template would involve the creation of `templates/vertical-pod-autoscaler.yaml` in the parent Helm chart (e.g. `microservice`).

```
{{- include "adp-helm-library.vertical-pod-autoscaler" (list . "microservice.vertical-pod-autoscaler") -}}
{{- define "microservice.vertical-pod-autoscaler" -}}
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
deployment:
  updateMode: <string>
```

### Storage Class template

* Template file: `_storage-class.yaml`
* Template name: `helm-library.storage-class`

A k8s `StorageClass`.  

A basic usage of this object template would involve the creation of `templates/storage-class.yaml` in the parent Helm chart (e.g. `microservice`).

```
{{- include "adp-helm-library.storage-class" (list . "microservice.storage-class") -}}
{{- define "microservice.storage-class" -}}
{{- end -}}
```

### Persistent Volume template

* Template file: `_persistent-volume.yaml`
* Template name: `helm-library.persistent-volume`

A k8s `PersistentVolume`.  

A basic usage of this object template would involve the creation of `templates/persistent-volume.yaml` in the parent Helm chart (e.g. `microservice`).

```
{{- include "adp-helm-library.persistent-volume" (list . "microservice.persistent-volume") -}}
{{- define "microservice.persistent-volume" -}}
{{- end -}}
```

### Persistent Volume Claim template

* Template file: `_persistent-volume-claim.yaml`
* Template name: `helm-library.persistent-volume-claim`

A k8s `PersistentVolumeClaim`.  

A basic usage of this object template would involve the creation of `templates/persistent-volume-claim.yaml` in the parent Helm chart (e.g. `microservice`).

```
{{- include "adp-helm-library.persistent-volume-claim" (list . "microservice.persistent-volume-claim") -}}
{{- define "microservice.persistent-volume-claim" -}}
{{- end -}}
```

## Helper templates

In addition to the K8s object templates described above, a number of helper templates are defined in `_helpers.tpl` that are both used within the library chart and available to use within a consuming parent chart.

### Default check required message

* Template name: `adp-helm-library.default-check-required-msg`
* Usage: `{{- include "adp-helm-library.default-check-required-msg" . }}`

A template defining the default message to print when checking for a required value within the library. This is not designed to be used outside of the library.

### Labels

* Template name: `adp-helm-library.labels`
* Usage: `{{- include "adp-helm-library.labels" . }}`

Common labels to apply to `metadata` of all K8s objects on the ADP K8s platform. This template relies on the globally required values [listed above](#all-template-required-values).

### Selector labels

* Template name: `adp-helm-library.selector-labels`
* Usage: `{{- include "adp-helm-library.selector-labels" . }}`

Common selector labels that can be applied where necessary to K8s objects on the ADP K8s platform. This template relies on the globally required values [listed above](#all-template-required-values).

### Http GET probe

* Template name: `adp-helm-library.http-get-probe`
* Usage: `{{- include "adp-helm-library.http-get-probe" (list . <map_of_probe_values>) }}`

Template for configuration of an http GET probe, which can be used for `readinessProbe` and/or `livenessProbe` in a container definition within a `Deployment` (see [container template](#container-template)). 

#### Required values
The following values need to be passed to the probe in the `<map_of_probe_values>`:

```
path: <string>
port: <integer>
initialDelaySeconds: <integer>
periodSeconds: <integer>
failureThreshold: <integer>
```

#### Optional values

```
timeoutSeconds: <integer>
```

### Exec probe

* Template name: `adp-helm-library.exec-probe`
* Usage: `{{- include "adp-helm-library.exec-probe" (list . <map_of_probe_values>) }}`

Template for configuration of an "exec" probe that runs a local script, which can be used for `readinessProbe` and/or `livenessProbe` in a container definition within a `Deployment` (see [container template](#container-template)).

#### Required values
The following values need to be passed to the probe in the `<map_of_probe_values>`:

```
script: <string>
initialDelaySeconds: <integer>
periodSeconds: <integer>
timeoutSeconds: <integer>
failureThreshold: <integer>
```

#### Optional values

```
timeoutSeconds: <integer>
```

### Cron Job template

* Template file: `_cron-job.yaml`
* Template name: `helm-library.cron-job`

A k8s `CronJob`.  

A basic usage of this object template would involve the creation of `templates/cron-job.yaml` in the parent Helm chart (e.g. `microservice`) that includes the template defined in `_container.yaml` template:

```
{{- include "helm-library.cron-job" (list . "microservice.cron-job") -}}
{{- define "microservice.cron-job" -}}
spec:
  template:
    spec:
      containers:
      - {{ include "helm-library.container" (list . "microservice.container") }}
{{- end -}}

```

## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3

The following attribution statement MUST be cited in your products and applications when using this information.

>Contains public sector information licensed under the Open Government license v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable information providers in the public sector to license the use and re-use of their information under a common open licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
