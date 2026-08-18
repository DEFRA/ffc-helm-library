#!/usr/bin/env bash

set -euo pipefail

: "${GH_TOKEN:?FFC_HELM_REPOSITORY_TOKEN is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

pull_requests="$(gh api \
  "repos/$GITHUB_REPOSITORY/pulls?state=open&base=master&per_page=100" \
  --jq '.[] | select(.head.repo.full_name == env.GITHUB_REPOSITORY) | [.number, .head.ref] | @tsv')"

while IFS=$'\t' read -r pr_number head_ref; do
  [ -n "$pr_number" ] || continue
  changed_files="$(gh api --paginate \
    "repos/$GITHUB_REPOSITORY/pulls/$pr_number/files?per_page=100" \
    --jq '.[].filename')"
  if grep -q '^ffc-helm-library/' <<< "$changed_files"; then
    echo "Refreshing PR #$pr_number from $head_ref"
    gh workflow run publish.yml \
      --repo "$GITHUB_REPOSITORY" \
      --ref master \
      -f channel=beta \
      -f "pr_number=$pr_number"
  fi
done <<< "$pull_requests"
