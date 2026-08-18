#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

assert_output() {
  expected="$1"
  output_file="$2"
  if ! grep -Fxq -- "$expected" "$output_file"; then
    echo "Expected output '$expected' in $output_file" >&2
    cat "$output_file" >&2
    exit 1
  fi
}

assert_contains() {
  expected="$1"
  output_file="$2"
  if ! grep -Fq -- "$expected" "$output_file"; then
    echo "Expected '$expected' in $output_file" >&2
    cat "$output_file" >&2
    exit 1
  fi
}

test_channel() {
  expected="$1"
  event_name="$2"
  ref_name="$3"
  requested_channel="$4"
  output_file="$temporary_directory/channel-output"
  : > "$output_file"

  EVENT_NAME="$event_name" \
    REF_NAME="$ref_name" \
    REQUESTED_CHANNEL="$requested_channel" \
    GITHUB_OUTPUT="$output_file" \
    bash "$repository_root/scripts/select-package-channel.sh"

  assert_output "channel=$expected" "$output_file"
}

test_decision() {
  expected="$1"
  event_name="$2"
  ref_name="$3"
  pr_number="$4"
  mock_output="$5"
  output_file="$temporary_directory/decision-output"
  : > "$output_file"

  PATH="$repository_root/tests/mocks:$PATH" \
    MOCK_GH_OUTPUT="$mock_output" \
    EVENT_NAME="$event_name" \
    REF_NAME="$ref_name" \
    PR_NUMBER="$pr_number" \
    REPOSITORY_OWNER=DEFRA \
    GH_TOKEN=test-token \
    GITHUB_REPOSITORY=DEFRA/ffc-helm-library \
    GITHUB_OUTPUT="$output_file" \
    bash "$repository_root/scripts/decide-build.sh"

  assert_output "should_package=$expected" "$output_file"
}

test_channel alpha push feature auto
test_channel beta pull_request 42/merge auto
test_channel beta pull_request_target master auto
test_channel release push master auto
test_channel validation merge_group gh-readonly-queue/master/pr-42 auto
test_channel beta workflow_dispatch feature beta

if EVENT_NAME=workflow_dispatch \
  REF_NAME=feature \
  REQUESTED_CHANNEL=release \
  GITHUB_OUTPUT="$temporary_directory/invalid-release-output" \
  bash "$repository_root/scripts/select-package-channel.sh" >/dev/null 2>&1; then
  echo 'Expected a release requested outside master to fail.' >&2
  exit 1
fi

test_decision false pull_request 42/merge 42 README.md
test_decision true pull_request 42/merge 42 ffc-helm-library/templates/_deployment.yaml
test_decision true pull_request_target master 42 ffc-helm-library/templates/_deployment.yaml
test_decision false push feature '' 1
test_decision true push feature '' 0
test_decision true push master '' ''
test_decision false merge_group gh-readonly-queue/master/pr-42 '' ''

publisher_output="$temporary_directory/publisher-output"
PATH="$repository_root/tests/mocks:$PATH" \
  GH_TOKEN=test-token \
  PUBLISHER_REPOSITORIES='DEFRA/ffc-helm-library DEFRA/ffc-helm-repository' \
  bash "$repository_root/scripts/verify-publisher-token.sh" > "$publisher_output"
assert_contains 'Authenticated as defradigitalci' "$publisher_output"
assert_contains 'write access confirmed for DEFRA/ffc-helm-repository' \
  "$publisher_output"

if PATH="$repository_root/tests/mocks:$PATH" \
  MOCK_DENIED_REPOSITORY=DEFRA/ffc-helm-repository \
  GH_TOKEN=test-token \
  PUBLISHER_REPOSITORIES='DEFRA/ffc-helm-library DEFRA/ffc-helm-repository' \
  bash "$repository_root/scripts/verify-publisher-token.sh" >/dev/null 2>&1; then
  echo 'Expected a publisher token without repository access to fail.' >&2
  exit 1
fi

chart_copy="$temporary_directory/Chart.yaml"
cp "$repository_root/ffc-helm-library/Chart.yaml" "$chart_copy"
current_version="$(python3 "$repository_root/scripts/chart-version.py" "$chart_copy")"
python3 "$repository_root/scripts/set-chart-version.py" \
  "$chart_copy" "$current_version" 5.2.99
if [ "$(python3 "$repository_root/scripts/chart-version.py" "$chart_copy")" != 5.2.99 ]; then
  echo 'set-chart-version.py did not update the chart version.' >&2
  exit 1
fi

version_remote="$temporary_directory/version-remote.git"
version_worktree="$temporary_directory/version-worktree"
git init --bare "$version_remote" >/dev/null
git clone "$version_remote" "$version_worktree" >/dev/null 2>&1
mkdir -p "$version_worktree/ffc-helm-library"
cp "$repository_root/ffc-helm-library/Chart.yaml" \
  "$version_worktree/ffc-helm-library/Chart.yaml"
python3 "$repository_root/scripts/set-chart-version.py" \
  "$version_worktree/ffc-helm-library/Chart.yaml" "$current_version" 5.2.1
git -C "$version_worktree" config user.name 'Pipeline test'
git -C "$version_worktree" config user.email 'pipeline-test@example.test'
git -C "$version_worktree" add ffc-helm-library/Chart.yaml
git -C "$version_worktree" commit -m 'Add test chart' >/dev/null
git -C "$version_worktree" branch -M master
git -C "$version_worktree" push origin master >/dev/null 2>&1
git -C "$version_worktree" switch -c feature >/dev/null

prepare_output="$temporary_directory/prepare-output"
(
  cd "$version_worktree"
  BASE_REF=master \
    HEAD_REF=feature \
    CHART_DIRECTORY=ffc-helm-library \
    CURRENT_VERSION=5.2.1 \
    PUBLISH_ENABLED=false \
    GITHUB_OUTPUT="$prepare_output" \
    bash "$repository_root/scripts/prepare-chart-version.sh"
)
assert_output 'changed=false' "$prepare_output"
assert_output 'version=5.2.2' "$prepare_output"
if [ "$(python3 "$repository_root/scripts/chart-version.py" \
  "$version_worktree/ffc-helm-library/Chart.yaml")" != 5.2.2 ]; then
  echo 'prepare-chart-version.sh did not calculate the next patch.' >&2
  exit 1
fi

git -C "$version_worktree" reset --hard HEAD >/dev/null
prepare_publish_output="$temporary_directory/prepare-publish-output"
(
  cd "$version_worktree"
  PATH="$repository_root/tests/mocks:$PATH" \
    GH_TOKEN=test-token \
    BASE_REF=master \
    HEAD_REF=feature \
    CHART_DIRECTORY=ffc-helm-library \
    CURRENT_VERSION=5.2.1 \
    PUBLISH_ENABLED=true \
    GITHUB_OUTPUT="$prepare_publish_output" \
    bash "$repository_root/scripts/prepare-chart-version.sh"
)
assert_output 'changed=true' "$prepare_publish_output"
assert_output 'version=5.2.2' "$prepare_publish_output"
remote_chart="$(git --git-dir="$version_remote" \
  show feature:ffc-helm-library/Chart.yaml)"
if ! grep -Fxq 'version: 5.2.2' <<< "$remote_chart"; then
  echo 'prepare-chart-version.sh did not push the resolved version.' >&2
  exit 1
fi

validation_output="$temporary_directory/validation-output"
CHART_DIRECTORY="$repository_root/ffc-helm-library" \
  GITHUB_OUTPUT="$validation_output" \
  bash "$repository_root/scripts/validate-chart-version.sh"
assert_output "version=$current_version" "$validation_output"

invalid_chart_directory="$temporary_directory/invalid-chart"
mkdir -p "$invalid_chart_directory"
cp "$repository_root/ffc-helm-library/Chart.yaml" \
  "$invalid_chart_directory/Chart.yaml"
python3 "$repository_root/scripts/set-chart-version.py" \
  "$invalid_chart_directory/Chart.yaml" "$current_version" 5.2
if CHART_DIRECTORY="$invalid_chart_directory" \
  GITHUB_OUTPUT="$temporary_directory/invalid-validation-output" \
  bash "$repository_root/scripts/validate-chart-version.sh" >/dev/null 2>&1; then
  echo 'Expected an invalid two-part chart version to fail validation.' >&2
  exit 1
fi

package_output="$temporary_directory/package-output"
RUNNER_TEMP="$temporary_directory" \
  CHART_DIRECTORY="$repository_root/ffc-helm-library" \
  CHART_VERSION="$current_version" \
  CHANNEL=beta \
  BUILD_NUMBER=42 \
  GITHUB_OUTPUT="$package_output" \
  bash "$repository_root/scripts/package-chart.sh" >/dev/null
assert_output "version=$current_version-beta.42" "$package_output"
test -f "$temporary_directory/chart-package/ffc-helm-library-$current_version-beta.42.tgz"

index_fixture="$repository_root/tests/fixtures/index.yaml"
python3 "$repository_root/scripts/index-has-chart-version.py" \
  "$index_fixture" ffc-helm-library 5.2.2-beta.42
if python3 "$repository_root/scripts/index-has-chart-version.py" \
  "$index_fixture" ffc-helm-library 9.9.9; then
  echo 'Expected an unknown chart version not to be found.' >&2
  exit 1
fi
if python3 "$repository_root/scripts/index-has-chart-version.py" \
  "$index_fixture" missing-chart 5.2.2-beta.42; then
  echo 'Expected a version belonging to another chart not to match.' >&2
  exit 1
fi

publish_seed="$temporary_directory/publish-seed"
publish_remote="$temporary_directory/publish-remote.git"
mkdir -p "$publish_seed"
cp "$temporary_directory/chart-package/ffc-helm-library-$current_version-beta.42.tgz" \
  "$publish_seed/"
helm repo index "$publish_seed" --url https://example.test/helm >/dev/null
git -C "$publish_seed" init >/dev/null
git -C "$publish_seed" config user.name 'Pipeline test'
git -C "$publish_seed" config user.email 'pipeline-test@example.test'
git -C "$publish_seed" add .
git -C "$publish_seed" commit -m 'Add existing chart' >/dev/null
git -C "$publish_seed" branch -M master
git clone --bare "$publish_seed" "$publish_remote" >/dev/null 2>&1

duplicate_run="$temporary_directory/publish-duplicate-run"
mkdir -p "$duplicate_run"
commits_before="$(git --git-dir="$publish_remote" rev-list --count master)"
PATH="$repository_root/tests/mocks:$PATH" \
  MOCK_GH_CLONE_SOURCE="$publish_remote" \
  GH_TOKEN=test-token \
  RUNNER_TEMP="$duplicate_run" \
  CHART_FILE="$temporary_directory/chart-package/ffc-helm-library-$current_version-beta.42.tgz" \
  CHART_NAME=ffc-helm-library \
  CHART_REPOSITORY=mock/ffc-helm-repository \
  CHART_REPOSITORY_BRANCH=master \
  CHART_REPOSITORY_URL=https://example.test/helm \
  CHART_VERSION="$current_version-beta.42" \
  bash "$repository_root/scripts/publish-chart.sh" >/dev/null
commits_after="$(git --git-dir="$publish_remote" rev-list --count master)"
if [ "$commits_after" != "$commits_before" ]; then
  echo 'Duplicate publication unexpectedly created a commit.' >&2
  exit 1
fi

new_package_run="$temporary_directory/new-package-run"
new_package_output="$temporary_directory/new-package-output"
mkdir -p "$new_package_run"
RUNNER_TEMP="$new_package_run" \
  CHART_DIRECTORY="$repository_root/ffc-helm-library" \
  CHART_VERSION="$current_version" \
  CHANNEL=beta \
  BUILD_NUMBER=43 \
  GITHUB_OUTPUT="$new_package_output" \
  bash "$repository_root/scripts/package-chart.sh" >/dev/null
new_chart_file="$new_package_run/chart-package/ffc-helm-library-$current_version-beta.43.tgz"

new_publish_run="$temporary_directory/publish-new-run"
mkdir -p "$new_publish_run"
PATH="$repository_root/tests/mocks:$PATH" \
  MOCK_GH_CLONE_SOURCE="$publish_remote" \
  GH_TOKEN=test-token \
  RUNNER_TEMP="$new_publish_run" \
  CHART_FILE="$new_chart_file" \
  CHART_NAME=ffc-helm-library \
  CHART_REPOSITORY=mock/ffc-helm-repository \
  CHART_REPOSITORY_BRANCH=master \
  CHART_REPOSITORY_URL=https://example.test/helm \
  CHART_VERSION="$current_version-beta.43" \
  bash "$repository_root/scripts/publish-chart.sh" >/dev/null

published_repository="$temporary_directory/published-repository"
git clone --quiet --branch master "$publish_remote" "$published_repository"
test -f "$published_repository/ffc-helm-library-$current_version-beta.43.tgz"
python3 "$repository_root/scripts/index-has-chart-version.py" \
  "$published_repository/index.yaml" \
  ffc-helm-library "$current_version-beta.43"

refresh_log="$temporary_directory/refresh-log"
PATH="$repository_root/tests/mocks:$PATH" \
  MOCK_PULL_REQUESTS=$'42\tfeature' \
  MOCK_CHANGED_FILES=ffc-helm-library/templates/_deployment.yaml \
  MOCK_GH_LOG="$refresh_log" \
  GH_TOKEN=test-token \
  GITHUB_REPOSITORY=DEFRA/ffc-helm-library \
  bash "$repository_root/scripts/refresh-open-pull-requests.sh"
assert_contains 'workflow run publish.yml' "$refresh_log"
assert_contains '--ref master' "$refresh_log"
assert_contains 'channel=beta' "$refresh_log"
assert_contains 'pr_number=42' "$refresh_log"

: > "$refresh_log"
PATH="$repository_root/tests/mocks:$PATH" \
  MOCK_PULL_REQUESTS=$'43\tdocumentation' \
  MOCK_CHANGED_FILES=README.md \
  MOCK_GH_LOG="$refresh_log" \
  GH_TOKEN=test-token \
  GITHUB_REPOSITORY=DEFRA/ffc-helm-library \
  bash "$repository_root/scripts/refresh-open-pull-requests.sh"
if [ -s "$refresh_log" ]; then
  echo 'A documentation-only pull request was unexpectedly refreshed.' >&2
  exit 1
fi

echo 'Pipeline script tests passed.'
