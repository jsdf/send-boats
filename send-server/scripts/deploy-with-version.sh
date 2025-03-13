#!/bin/bash

# Get the current git SHA
GIT_SHA=$(git rev-parse --short HEAD)

# Check if there are uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    GIT_DIRTY="true"
else
    GIT_DIRTY="false"
fi

echo "Deploying with version: SHA=${GIT_SHA}, isDirty=${GIT_DIRTY}"

# Deploy with environment variables
wrangler deploy --var GIT_SHA:"${GIT_SHA}" --var GIT_DIRTY:"${GIT_DIRTY}"
