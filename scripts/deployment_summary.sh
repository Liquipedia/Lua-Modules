#!/bin/bash

DEV_ENV_NAME="$1"
BASE_SHA="$2"
DEPLOY_SHA="$3"
FILES_COUNT="$4"

echo "### Deployment Summary" >> $GITHUB_STEP_SUMMARY
echo "- **Environment**: dev/${DEV_ENV_NAME}" >> $GITHUB_STEP_SUMMARY
echo "- **Base SHA**: ${BASE_SHA}" >> $GITHUB_STEP_SUMMARY
echo "- **Deploy SHA**: ${DEPLOY_SHA}" >> $GITHUB_STEP_SUMMARY
echo "- **Files deployed**: ${FILES_COUNT}" >> $GITHUB_STEP_SUMMARY
