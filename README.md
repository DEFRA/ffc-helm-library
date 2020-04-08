# FFC Platform Helm Library Chart

A Helm library chart that captures general configuration for the FFC Kubernetes platform. It can be used by any FFC microservice Helm chart to import k8s object templates configured to run on the FFC platform.

## Including the library chart

In your microservice Helm chart:
  * Update `Chart.yaml` to `apiVersion: v2`.
  * Add the library chart under `dependencies` and choose the version you want (example below). Version number can include `~` or `^` to pick up latest PATCH and MINOR versions respectively.
  * Issue the following commands to add the repo that contains the library chart, update the repo, then update dependencies in your Helm chart:

```
helm repo add ffc https://raw.githubusercontent.com/defra/ffc-helm-repository/master/
helm repo update
helm dependency update <helm_chart_location>
```

An example FFC microservice `Chart.yaml`:

```
apiVersion: v2
description: A Helm chart to deploy a microservice to the FFC Kubernetes platform
name: ffc-microservice
version: 1.0.0
dependencies:
- name: ffc-helm-library
  version: ^1.0.0
  repository: https://raw.githubusercontent.com/defra/ffc-helm-repository/master/
```

## Using the k8s object templates

First, follow [the instructions](#including-the-library-chart) for including the FFC Helm library chart.

The FFC Helm library chart has been configured using the conventions described in the [Helm library chart documentation](https://helm.sh/docs/topics/library_charts/). The k8s object templates provide settings shared by all objects of that type, which can be augmented with extra settings from the parent (FFC microservice) chart. The library object templates will merge the library and parent templates. In the case where settings are defined in both the library and parent chart, the parent chart settings will take precedence, so library chart settings can be overridden. The library object templates will expect values to be set in the parent `.values.yaml`. Any required values (defined for each template below) that are not provided will result in an error message when processing the template (`helm install`, `helm upgrade`, `helm template`).

The general strategy for using one of the library templates in the parent microservice Helm chart is to create a template for the k8s object formateted as so:

```
{{- include "ffc-helm-library.secret" (list . "ffc-microservice.secret") -}}
{{- define "ffc-microservice.secret" -}}
# Microservice specific configuration in here
{{- end -}}
```

This example would be for `template/secret.yaml` in the `ffc-microservice` Helm chart. The initial `include` statement can be wrapped in an `if` statement if you only wish to create the k8s object based on a condition. E.g., only create the secret is a `pr` value has been set in `values.yaml`:

```
{{- if .Values.pr }}
{{- include "ffc-helm-library.secret" (list . "ffc-microservice.secret") -}}
{{- end }}
{{- define "ffc-microservice.secret" -}}
{{- end -}}
```


### All template required values

All the k8s object templates in the library require the following values to be set in the parent microservice Helm chart's `values.yaml`:

```
name: <string>
namespace: <string>
environment: <string>
```

### Cluster IP service template

Template file: `_cluster-ip-service.yaml`

A k8s `Service` object of type `ClusterIP`.

A basic usage of this object template would involve the creation of `templates/cluster-ip-service.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
{{- include "ffc-helm-library.cluster-ip-service" (list . "ffc-microservice.cluster-ip-service") -}}
{{- define "ffc-microservice.cluster-ip-service" -}}
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
container:
  port: <integer>
```

### Container template

Template file: `_container.yaml`

A template for the container definition to be used within a k8s `Deployment` object.

A basic usage of this object template would involve the creation of `templates/_container.yaml` in the parent Helm chart (e.g. `ffc-microservice`). Note the `_` in the name. This template is part of the `Deployment` object definition and will be used in conjunction the `_deployment.yaml` template ([see below](#deployment-template)). As a minimum, `templates/_container.yaml` would define environment variables and liveness/readiness probes, e.g.:

```
{{- define "ffc-microservice.container" -}}
env: <list>
livenessProbe:
readinessProbe:
{{- end -}}

```

The liveness and readiness probes could take advantage of the helper templates for [http GET probe](#http-get-probe) and [exec probe](#exec-probe) defined within the library chart and described below.

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
image: <string>
container:
  imagePullPolicy: <string>
  readOnlyRootFilesystem: <boolean>
  allowPrivilegeEscalation: <boolean>
  requestMemory: <string>
  requestCpu: <string>
  limitMemory: <string>
  limitCpu: <string>
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to enable a command with arguments to run within the container:

```
container:
  command: <list of strings>
  args: <list of strings>
```

### Deployment template

Template file: `_deployment.yaml`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/deployment.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
TODO
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
deployment:
  replicas: <integer>
  minReadySeconds: <integer>
  redeployOnChange: <string>
  priorityClassName: <string>
  restartPolicy: <string>
  runAsUser: <integer>
  runAsNonRoot: <boolean>
```


#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to enable the respective configuration:

```
deployment:
  imagePullSecret: <string>
```

### EKS service account template

Template file: `_eks-service-account.yaml`

A k8s `ServiceAccount` object configured for use on AWS's managed k8s service EKS.

A basic usage of this object template would involve the creation of `templates/eks-service-account.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
{{- include "ffc-helm-library.eks-service-account" (list . "ffc-microservice.eks-service-account") -}}
{{- define "ffc-microservice.eks-service-account" -}}
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
serviceAccount:
  name: <string>
  roleArn: <string>
```

### Ingress template

Template file: `_ingress.yaml`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

(TODO: nginx vs alb)

```
TODO
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
ingress:
  class: <string>
container:
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

### Postgres service template

Template file: `_postgres-service.yaml`

(TODO: add description - this is an external service type)

A basic usage of this object template would involve the creation of `templates/postgres-service.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
TODO
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
* Template name: `ffc-helm-library.role-binding`

(TODO: add description, intended only for PR so include the if in the template (TODO TODO))

A basic usage of this object template would involve the creation of `templates/role-binding.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
TODO
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
workstream: <string>
```

### Secret template

* Template file: `_secret.yaml`
* Template name: `ffc-helm-library.secret`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/secret.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

(Include the required data override)

```
TODO
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
* Template name: `ffc-helm-library.service`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/secret.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

(Include the required data override)

```
TODO
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
service:
  type: <string>
```

## Helper templates

In addition to the k8s object templates described above, a number of helper templates are defined in `_helpers.tpl` that are both used within the library chart and available to use within a consuming parent chart.

### Default check required message

Template name: `ffc-helm-library.default-check-required-msg`

(TODO: add description and usage)

### Labels

Template name: `ffc-helm-library.labels`

(TODO: add description and usage)

### Selector labels

Template name: `ffc-helm-library.selector-labels`

(TODO: add description and usage)

### Http GET probe

Template name: `ffc-helm-library.http-get-probe`

(TODO: add description and usage)

Settings for an http GET probe to be used for readiness or liveness

### Exec probe

Template name: `ffc-helm-library.exec-probe`

(TODO: add description and usage)

Settings for a Node exec probe to be used for readiness or liveness
