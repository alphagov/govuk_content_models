#!/bin/bash
set -e
rm -f Gemfile.lock
bundle install --path "${HOME}/bundles/${JOB_NAME}"
export GOVUK_APP_DOMAIN=development
govuk_setenv default bundle exec rake test
govuk_setenv default bundle exec rake publish_gem
