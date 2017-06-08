# -*- encoding: utf-8 -*-
require File.expand_path('../lib/govuk_content_models/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Battley"]
  gem.email         = ["pbattley@gmail.com"]
  gem.description   = %q{Shared models for Panopticon and Publisher}
  gem.summary       = %q{Shared models for Panopticon and Publisher, as a Rails Engine}
  gem.homepage      = "https://github.com/alphagov/govuk_content_models"

  gem.files         = `git ls-files`.split($\).reject { |f| f.include?('test/') }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.name          = "govuk_content_models"
  gem.require_paths = ["lib", "app"]
  gem.version       = GovukContentModels::VERSION

  gem.add_dependency "bson_ext"
  gem.add_dependency "gds-api-adapters", ">= 10.9.0"

  gem.add_dependency "gds-sso",          "~> 13.2"
  gem.add_dependency "govspeak",         "~> 3.1"
  gem.add_dependency "mongoid",          "6.1.0"
  gem.add_dependency "state_machines",   "~> 0.4"
  gem.add_dependency "state_machines-mongoid", "~> 0.1"
  gem.add_dependency "plek"

  gem.add_development_dependency "database_cleaner", "1.5.1"
  gem.add_development_dependency "factory_girl", "4.8.0"
  gem.add_development_dependency "gem_publisher", "1.2.0"
  gem.add_development_dependency "mocha", "1.1.0"
  gem.add_development_dependency "multi_json"
  gem.add_development_dependency "rake", "0.9.2.2"
  gem.add_development_dependency "webmock", "1.22.6"
  gem.add_development_dependency "shoulda-context", "1.2.1"
  gem.add_development_dependency "timecop", "0.5.9.2"
  gem.add_development_dependency 'govuk-lint', '~> 0.5.1'
  gem.add_development_dependency 'pry-byebug'

  # The following are added to help bundler resolve dependencies
  gem.add_development_dependency "rack", "~> 2.0.1"
  gem.add_development_dependency "rails", "= 5.0.2"
end
