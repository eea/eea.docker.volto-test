#!/bin/bash
set -e

if [ -z "$GIT_URL" ]; then
  GIT_URL="https://github.com"
fi

if [ -z "$GIT_BRANCH" ]; then
  GIT_BRANCH="master"
fi

if [ -z "$GIT_USER" ]; then
  GIT_USER="eea"
fi

if [ -z "$GIT_NAME" ]; then
  echo "GIT_NAME is required"
  exit 1
fi

PACKAGE="$GIT_NAME"
if [ ! -z "$NAMESPACE" ]; then
  PACKAGE="$NAMESPACE/$GIT_NAME"
fi

WORKSPACES="--workspace src/addons/$GIT_NAME"
ADDONS="--addon $PACKAGE"

if [ ! -z "$DEPENDENCIES" ]; then
  for dep in $DEPENDENCIES; do
    ADDONS="$ADDONS --addon $dep"
  done
fi

cd /opt/frontend/my-volto-project
yo --force --no-insight @plone/volto --no-interactive --skip-install $WORKSPACES $ADDONS

if [ ! -d "/opt/frontend/my-volto-project/src/addons/$GIT_NAME" ]; then
  cd /opt/frontend/my-volto-project/src/addons/
  git clone "$GIT_URL/$GIT_USER/$GIT_NAME"
  cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME
  if [ ! -z "$GIT_CHANGE_ID" ]; then
    GIT_BRANCH=PR-${GIT_CHANGE_ID}
    git fetch origin pull/$GIT_CHANGE_ID/head:$GIT_BRANCH
  fi
  git checkout $GIT_BRANCH
  cd /opt/frontend/my-volto-project/
fi

yarn

if [[ "$1" == "test"* ]]; then
  node /jsconfig $PACKAGE src/addons/$GIT_NAME
  yarn add -W --dev jest-junit
  exec bash -c "set -o pipefail; ./node_modules/jest/bin/jest.js --env=jsdom --passWithNoTests src/addons/$GIT_NAME --watchAll=false --reporters=default --reporters=jest-junit --collectCoverage --coverageReporters lcov cobertura text 2>&1 | tee -a unit_tests_log.txt"
fi

cd /opt/frontend/my-volto-project/src/addons/$GIT_NAME
if [[ "$1" == "eslint"* ]]; then
  exec ../../../node_modules/eslint/bin/eslint.js --max-warnings=0 'src/**/*.{js,jsx,json}'
fi

if [[ "$1" == "stylelint"* ]]; then
  exec ../../../node_modules/stylelint/bin/stylelint.js 'src/**/*.{css,less}'
fi

if [[ "$1" == "prettier"* ]]; then
  exec ../../../node_modules/.bin/prettier --single-quote --check 'src/**/*.{js,jsx,json,css,less,md}'
fi

exec "$@"
