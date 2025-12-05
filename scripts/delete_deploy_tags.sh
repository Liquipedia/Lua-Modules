#!/bin/bash

DEV_ENV_NAME="$1"
INCLUDE_SUB_ENVS="${2:-false}"
TAG_PATTERN="dev/${DEV_ENV_NAME}"

if [[ "$INCLUDE_SUB_ENVS" == "true" ]]; then
  TAGS=$(git tag -l "${TAG_PATTERN}*/last-deploy" 2>/dev/null || true)
else
  TAGS=$(git tag -l "${TAG_PATTERN}/last-deploy" 2>/dev/null || true)
fi

if [[ -n "$TAGS" ]]; then
  echo "### Deployment Tags Deleted" >> $GITHUB_STEP_SUMMARY
  echo "Deleting deployment tags:"
  TAG_COUNT=0
  for TAG in $TAGS; do
    echo "  - $TAG"
    echo "- \`$TAG\`" >> $GITHUB_STEP_SUMMARY
    git tag -d "$TAG"
    if git push origin ":refs/tags/$TAG" 2>/dev/null; then
      TAG_COUNT=$((TAG_COUNT + 1))
    else
      echo "::warning::Failed to delete remote tag $TAG"
    fi
  done
  echo "Deleted $TAG_COUNT deployment tag(s)"
else
  echo "No deployment tags found for dev/${DEV_ENV_NAME}"
  echo "### Deployment Tags" >> $GITHUB_STEP_SUMMARY
  echo "No deployment tags found for \`dev/${DEV_ENV_NAME}\`" >> $GITHUB_STEP_SUMMARY
fi
