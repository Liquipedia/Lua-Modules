#!/bin/bash

DEV_ENV_NAME="$1"
TAG_NAME="dev/${DEV_ENV_NAME}/last-deploy"

if git rev-parse "refs/tags/$TAG_NAME" >/dev/null 2>&1; then
  LAST_DEPLOY_SHA=$(git rev-parse "refs/tags/$TAG_NAME")
  echo "sha=$LAST_DEPLOY_SHA" >> $GITHUB_OUTPUT
  echo "found=true" >> $GITHUB_OUTPUT
  echo "Found last deploy tag at $LAST_DEPLOY_SHA"
else
  echo "found=false" >> $GITHUB_OUTPUT
  echo "No previous deploy tag found, will use fork point"
fi
