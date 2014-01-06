# -*- encoding: utf-8 -*-
require File.expand_path('../lib/govuk_content_models/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Battley"]
  gem.email         = ["pbattley@gmail.com"]
  gem.description   = %q{Shared models for Panopticon and Publisher}
  gem.summary       = %q{Shared models for Panopticon and Publisher, as a Rails Engine}
  gem.homepage      = "https://github.com/alphagov/govuk_content_models"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "govuk_content_models"
  gem.require_paths = ["lib", "app"]
  gem.version       = GovukContentModels::VERSION

  gem.add_dependency "bson_ext"
  gem.add_dependency "differ"
  gem.add_dependency "gds-api-adapters"

  gem.add_dependency "gds-sso",          ">= 3.0.0", "< 4.0.0"
  gem.add_dependency "govspeak",         ">= 1.0.1", "< 2.0.0"
  # Mongoid 2.5.0 supports the newer 1.7.x and 1.8.x Mongo drivers
  gem.add_dependency "mongoid",          "~> 2.5"
  gem.add_dependency "plek"
  gem.add_dependency "state_machine"

  gem.add_development_dependency "database_cleaner", "0.7.2"
  gem.add_development_dependency "factory_girl", "3.3.0"
  gem.add_development_dependency "gem_publisher", "1.2.0"
  gem.add_development_dependency "mocha", "0.13.3"
  gem.add_development_dependency "multi_json", "1.3.7" # Pinned to allow dependency resolution
  gem.add_development_dependency "rake", "0.9.2.2"
  gem.add_development_dependency "webmock", "1.8.7"
  gem.add_development_dependency "shoulda-context", "1.0.0"
  gem.add_development_dependency "timecop", "0.5.9.2"

  # The following are added to help bundler resolve dependencies
  gem.add_development_dependency "rack", "~> 1.4.4"
  gem.add_development_dependency "rails", "= 3.2.13"
end
