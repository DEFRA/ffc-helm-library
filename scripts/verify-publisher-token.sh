#!/usr/bin/env bash

set -euo pipefail

: "${GH_TOKEN:?FFC_HELM_REPOSITORY_TOKEN is not configured}"
: "${PUBLISHER_REPOSITORIES:?PUBLISHER_REPOSITORIES is required}"

publisher="$(gh api user --jq .login)"
echo "::notice title=Helm publisher identity::Authenticated as $publisher"

for repository in $PUBLISHER_REPOSITORIES; do
  if [ "$(gh api "repos/$repository" --jq '.permissions.push // false')" != true ]; then
    echo "Publisher token does not have write access to $repository." >&2
    exit 1
  fi
  echo "Publisher token write access confirmed for $repository."
done
