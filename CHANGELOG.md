# Change log

All notable changes to this project will be documented in this file.

---

## 5.2.2

Retired the Jenkins pipeline and replaced it with a GitHub Actions workflow for
testing, versioning, packaging and publishing the Helm library chart.

- Feature branches publish uniquely numbered `alpha.<run-number>` packages
  until an open pull request targets `master`.
- Pull requests publish uniquely numbered `beta.<run-number>` packages, and a
  merge to `master` automatically publishes the full `MAJOR.MINOR.PATCH`
  release.
- Packages and the regenerated Helm `index.yaml` are committed directly to
  `DEFRA/ffc-helm-repository`, preserving the previous Jenkins distribution
  model.
- Patch versions are advanced automatically when required. Deliberate major or
  minor changes reset the patch to `0`, while major/minor regressions are
  rejected.
- Stale branches are rebased where possible and open chart pull requests are
  refreshed after another release consumes their proposed patch version.
- Every workflow run executes the Helm consumer, versioning and publishing
  tests through `pytest`, with named Bash cases, a GitHub job summary and a
  downloadable JUnit XML report.
- Pull-request required checks and merge-queue validation run without creating
  unnecessary packages, and duplicate immutable chart versions are detected
  before the Helm index is regenerated.
- Pull-request tests and privileged publication now run on separate runners;
  publication uses the trusted base workflow and scripts so pull-request code
  cannot access the cross-repository publisher PAT. Fork PRs are validation-only.
- Corrected and expanded the README's template names, value keys, required
  storage and CronJob settings, KEDA example, publisher permissions and
  pipeline execution order, with automated documentation consistency tests.
- GitHub Actions dependencies use their Node.js 24-compatible releases.

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
