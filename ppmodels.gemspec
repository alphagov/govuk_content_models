# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ppmodels/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Battley"]
  gem.email         = ["pbattley@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ppmodels"
  gem.require_paths = ["lib"]
  gem.version       = Ppmodels::VERSION

  gem.add_development_dependency "fakeweb"
  gem.add_development_dependency "active_support"
  gem.add_development_dependency "rake"
  gem.add_dependency "mongoid"
  gem.add_dependency "bson_ext"
end
