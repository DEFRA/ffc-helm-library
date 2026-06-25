# Change log

All notable changes to this project will be documented in this file.

---

## 5.2.1

Container Linux capabilities are now configurable and default to none.
`_container.yaml` previously hardcoded `add: [NET_BIND_SERVICE, SYS_TIME]` after `drop: ALL`, which could not be overridden by consuming charts and left unnecessary privileges in the effective capability set.
Charts that require a specific capability can now opt in via `container.capabilities.add`. When unset, no capabilities are added, satisfying the Kubernetes restricted Pod Security Standard and the "allowed capabilities" cluster policy.

---

## 5.2.0

Added `enableReloader` option to Deployment, StatefulSet, and CronJob templates.
When enabled (defaults to `true`), adds the `reloader.stakater.com/auto: "true"` annotation to the workload metadata, enabling automatic rolling restarts when referenced ConfigMaps or Secrets change. Requires Stakater Reloader to be installed in the cluster.
Services can opt out by setting `deployment.enableReloader: false`.
Replaces the previous `randAlphaNum` redeploy hack with the Stakater Reloader annotation.

---

## 4.9.0

Updated the default behavior of `automountServiceAccountToken` to `false`
Users can override this by setting the value to `true` in `values.yaml`
Documented the optional `automountServiceAccountToken` value in the README under `optional values`

---
