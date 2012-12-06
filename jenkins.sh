#!/bin/bash
set -e
rm -f Gemfile.lock
bundle install --path "${HOME}/bundles/${JOB_NAME}"
export GOVUK_APP_DOMAIN=development
bundle exec rake test
bundle exec rake publish_gem
