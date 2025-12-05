#!/bin/bash

DEV_ENV_NAME="$1"
COMMIT_SHA="${2:-HEAD}"
TAG_NAME="dev/${DEV_ENV_NAME}/last-deploy"

echo "Updating deployment tag: $TAG_NAME to $COMMIT_SHA"
git tag -f "$TAG_NAME" "$COMMIT_SHA"
git push -f origin "$TAG_NAME"
