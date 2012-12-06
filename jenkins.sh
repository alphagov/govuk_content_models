#!/bin/bash
set -e
rm -f Gemfile.lock
bundle install --path "${HOME}/bundles/${JOB_NAME}"
govuk_setenv default bundle exec rake test
govuk_setenv default bundle exec rake publish_gem
