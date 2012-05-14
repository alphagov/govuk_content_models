# -*- encoding: utf-8 -*-
require File.expand_path('../lib/govuk_content_models/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Battley"]
  gem.email         = ["pbattley@gmail.com"]
  gem.description   = %q{Shared models for Panopticon and Publisher}
  gem.summary       = %q{Shared models for Panopticon and Publisher, as a Rails Engine}
  gem.homepage      = "https://github.com/alphagov/gds_content_models"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "govuk_content_models"
  gem.require_paths = ["lib", "app"]
  gem.version       = GovukContentModels::VERSION

  gem.add_dependency "mongoid"
  gem.add_dependency "bson_ext"
  gem.add_dependency "plek"
  gem.add_dependency "gds-api-adapters"

  gem.add_development_dependency "fakeweb"
  gem.add_development_dependency "active_support"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "database_cleaner"
  gem.add_development_dependency "gem_publisher"
end
