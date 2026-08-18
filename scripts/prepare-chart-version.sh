#!/usr/bin/env bash

set -euo pipefail

: "${BASE_REF:?BASE_REF is required}"
: "${HEAD_REF:?HEAD_REF is required}"
: "${CHART_DIRECTORY:?CHART_DIRECTORY is required}"
: "${CURRENT_VERSION:?CURRENT_VERSION is required}"
: "${PUBLISH_ENABLED:?PUBLISH_ENABLED is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chart_file="$CHART_DIRECTORY/Chart.yaml"

git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'

if [ -n "${GH_TOKEN:-}" ]; then
  gh auth setup-git
fi

git fetch origin "$BASE_REF"
previous_version="$(
  git show "origin/$BASE_REF:$chart_file" |
    python3 "$script_directory/chart-version.py" -
)"
test -n "$previous_version"

rebased=false
if ! git merge-base --is-ancestor "origin/$BASE_REF" HEAD; then
  echo "Branch is behind $BASE_REF; rebasing before recalculating the chart version."
  if ! git rebase "origin/$BASE_REF"; then
    git rebase --abort
    echo 'Automatic rebase failed. Resolve the conflict and push the rebased branch.' >&2
    exit 1
  fi
  CURRENT_VERSION="$(python3 "$script_directory/chart-version.py" "$chart_file")"
  rebased=true
fi

resolved_version="$(
  python3 "$script_directory/resolve-chart-version.py" \
    "$previous_version" "$CURRENT_VERSION"
)"

version_changed=false
if [ "$resolved_version" != "$CURRENT_VERSION" ]; then
  python3 "$script_directory/set-chart-version.py" \
    "$chart_file" "$CURRENT_VERSION" "$resolved_version"
  version_changed=true
fi

changed=false
if [ "$version_changed" = true ] || [ "$rebased" = true ]; then
  if [ "$PUBLISH_ENABLED" = true ]; then
    : "${GH_TOKEN:?FFC_HELM_REPOSITORY_TOKEN is required to update the branch}"
    if [ "$version_changed" = true ]; then
      git add -- "$chart_file"
      git commit -m "Bump chart version to $resolved_version"
    fi
    git push --force-with-lease origin "HEAD:$HEAD_REF"
    changed=true
  else
    echo "Dry run: would update $HEAD_REF to chart version $resolved_version."
  fi
fi

printf 'changed=%s\n' "$changed" >> "$GITHUB_OUTPUT"
printf 'version=%s\n' "$resolved_version" >> "$GITHUB_OUTPUT"
