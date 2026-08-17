#!/usr/bin/env bash

set -euo pipefail

: "${CHART_FILE:?CHART_FILE is required}"
: "${CHART_NAME:?CHART_NAME is required}"
: "${CHART_REPOSITORY:?CHART_REPOSITORY is required}"
: "${CHART_REPOSITORY_BRANCH:?CHART_REPOSITORY_BRANCH is required}"
: "${CHART_REPOSITORY_URL:?CHART_REPOSITORY_URL is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"
: "${GH_TOKEN:?FFC_HELM_REPOSITORY_TOKEN is required}"
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_directory="$RUNNER_TEMP/helm-repository"
index_directory="$RUNNER_TEMP/helm-index"
package_name="$(basename "$CHART_FILE")"

gh auth setup-git
gh repo clone "$CHART_REPOSITORY" "$repository_directory" -- \
  --branch "$CHART_REPOSITORY_BRANCH"

cd "$repository_directory"
git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'

mkdir -p "$index_directory"
cp "$CHART_FILE" "$index_directory/"

for attempt in 1 2 3; do
  git fetch origin "$CHART_REPOSITORY_BRANCH"
  git reset --hard "origin/$CHART_REPOSITORY_BRANCH"

  if python3 "$script_directory/index-has-chart-version.py" \
    index.yaml "$CHART_NAME" "$CHART_VERSION"; then
    if [ ! -f "$package_name" ]; then
      echo "Index contains $CHART_NAME $CHART_VERSION but $package_name is missing." >&2
      exit 1
    fi
    echo "Chart $CHART_VERSION is already published."
    exit 0
  fi

  if [ -e "$package_name" ]; then
    echo "$package_name already exists without a matching index entry." >&2
    exit 1
  fi

  cp "$CHART_FILE" .
  helm repo index "$index_directory" \
    --merge "$repository_directory/index.yaml" \
    --url "$CHART_REPOSITORY_URL"
  cp "$index_directory/index.yaml" index.yaml
  git add -- "$package_name" index.yaml
  git commit -m "Add new version $CHART_VERSION"

  push_output=''
  if push_output="$(git push origin "HEAD:$CHART_REPOSITORY_BRANCH" 2>&1)"; then
    echo "Published chart $CHART_VERSION directly to $CHART_REPOSITORY_BRANCH."
    exit 0
  fi

  push_message="$(printf '%s\n' "$push_output" | tail -n 4 | tr '\n' ' ')"
  push_message="${push_message//'%'/'%25'}"
  push_message="${push_message//$'\r'/'%0D'}"
  push_message="${push_message//$'\n'/'%0A'}"
  echo "::warning title=Helm repository push rejected::Attempt $attempt: $push_message"

  if [ "$attempt" = 3 ]; then
    echo '::error title=Helm repository publication blocked::Direct publication requires defradigitalci to have bypass permission for the protected master branch.'
    exit 1
  fi
done
