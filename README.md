# FFC Platform Helm Library Chart

A Helm library chart that captures general configuration for the FFC Kubernetes platform (MORE HERE)

## Including the library chart

Steps:
  * Update `Chart.yaml` to `apiVersion: v2`
  * Add library chart under `dependencies`. Choose the version you want. Version number can include `~` or `^` to pick up latest PATCH and MINOR versions respectively
  * Need to do `helm dependency update` (check if need to do add helm repo -- see Helm chart documentation)

An example `Chart.yaml`:

```
apiVersion: v2
description: A Helm chart to deploy a microservices to FFC Kubernetes platform
name: ffc-microservice
version: 1.0.0
dependencies:
- name: ffc-helm-library
  version: ^1.0.0
  repository: https://raw.githubusercontent.com/defra/ffc-helm-repository/master/
```

## Using the k8s object templates

(Follow instructions for using the library chart)

(Intro text here, generally how you use the templates. Basically include the library template and pass it the template defined in the parent helm chart)

(TODO: include an example of an IF statement)

```
{{- include "ffc-helm-library.secret" (list . "ffc-microservice.secret") -}}
{{- define "ffc-microservice.secret" -}}
# Microservice specific configuration in here
{{- end -}}
```

### All template required values

All the object templates include labels (TODO: list them and any other globals)

```
name: <value>
namespace: <value>
```

### AWS service account template

Template file: `_aws-service-account.yaml`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/aws-service-account.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
{{- include "ffc-helm-library.aws-service-account" (list . "ffc-microservice.aws-service-account") -}}
{{- define "ffc-microservice.aws-service-account" -}}
{{- end -}}
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
serviceAccount: <value>
  name: <value>
  roleArn: <value>
```

### Cluster IP service template

Template file: `_cluster-ip-service.yaml`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/cluster-ip-service.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
{{- include "ffc-helm-library.cluster-ip-service" (list . "ffc-microservice.cluster-ip-service") -}}
{{- define "ffc-microservice.cluster-ip-service" -}}
{{- end -}}
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
```

### Container template

Template file: `_container.yaml`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/_container.yaml` in the parent Helm chart (e.g. `ffc-microservice`). Note the `_` in the name. This template is part of the `deployment` object definition and will be used within the `deployment.yaml` ([see below](#deployment-template)). As a minimum, `templates/_container.yaml` would contain:

```
TODO
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
```

name
image
container.imagePullPolicy
container.readOnlyRootFilesystem
container.allowPrivilegeEscalation
container.requestMemory
container.requestCpu
container.limitMemory
container.limitCpu

#### Optional values

container.command
container.args




### Deployment template

Template file: `_deployment.yaml`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/deployment.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
TODO
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
```

name
namespace
deployment.replicas
deployment.minReadySeconds
deployment.redeployOnChange
deployment.priorityClassName
deployment.restartPolicy
deployment.runAsUser
deployment.runAsNonRoot

#### Optional values

deployment.imagePullSecret

### Ingress template

Template file: `_ingress.yaml`

(TODO: add description)

A basic usage of this object template would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

(TODO: nginx vs alb)

```
TODO
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
ingress.class
container.port
```

#### Optional values

```
pr
ingress.endpoint
ingress.server
```

### Postgres service template

Template file: `_postgres-service.yaml`

(TODO: add description - this is an external service type)

A basic usage of this object template would involve the creation of `templates/postgres-service.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
TODO
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
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

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
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

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
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

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
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
