#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
resolver="$repository_root/scripts/resolve-chart-version.py"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

assert_version() {
  expected="$1"
  previous="$2"
  current="$3"
  actual="$(python3 "$resolver" "$previous" "$current")"
  if [ "$actual" != "$expected" ]; then
    echo "Expected $previous + $current to resolve to $expected; found $actual" >&2
    exit 1
  fi
}

assert_rejected() {
  previous="$1"
  current="$2"
  if python3 "$resolver" "$previous" "$current" >/dev/null 2>&1; then
    echo "Expected $previous + $current to be rejected" >&2
    exit 1
  fi
}

assert_version 5.2.2 5.2.1 5.2.1
assert_version 5.2.2 5.2.1 5.2.0
assert_version 5.2.4 5.2.1 5.2.4
assert_version 5.3.0 5.2.1 5.3.7
assert_version 6.0.0 5.2.1 6.0.9
assert_rejected 5.2.1 5.1.9
assert_rejected 5.2.1 4.9.9
assert_rejected 5.2.1 5.2

helm package "$repository_root/ffc-helm-library" \
  --version 5.2.2-alpha.42 \
  --destination "$temporary_directory" >/dev/null
helm package "$repository_root/ffc-helm-library" \
  --version 5.2.2-beta.42 \
  --destination "$temporary_directory" >/dev/null
helm package "$repository_root/ffc-helm-library" \
  --version 5.2.2 \
  --destination "$temporary_directory" >/dev/null

for package in \
  ffc-helm-library-5.2.2-alpha.42.tgz \
  ffc-helm-library-5.2.2-beta.42.tgz \
  ffc-helm-library-5.2.2.tgz; do
  test -f "$temporary_directory/$package"
done

echo 'Chart versioning and package-name tests passed.'
