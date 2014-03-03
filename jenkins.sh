#!/bin/bash
set -e
rm -f Gemfile.lock
bundle install --path "${HOME}/bundles/${JOB_NAME}"
export GOVUK_APP_DOMAIN=dev.gov.uk
bundle exec rake
if [[ -n "$PUBLISH_GEM" ]]; then
  bundle exec rake publish_gem
fi
