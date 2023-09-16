#!/usr/bin/env bash

[[ $BITBUCKET_EXIT_CODE = 1 ]] && STATUS="failed" || STATUS="finished"
REPO="https://bitbucket.org/${BITBUCKET_REPO_OWNER}/${BITBUCKET_REPO_SLUG}"
PIPELINE_LINK="<a href='${REPO}/addon/pipelines/home#"'!'"/results/${BITBUCKET_BUILD_NUMBER}'>pipeline</a>"
COMMIT_LINK="<a href='${REPO}/commits/${BITBUCKET_COMMIT}'>${BITBUCKET_COMMIT}</a>"
MESSAGE="Branch [<b>${BITBUCKET_BRANCH}</b>] $PIPELINE_LINK deployment $STATUS. Triggered by commit: ${COMMIT_LINK}."
curl -s -X POST -w "%{http_code}" -H "Content-Type: application/json" -d "{ \"attachments\": [{ \"views\": { \"flockml\": \"${MESSAGE}\" } }] }" $WEBHOOK_URL
