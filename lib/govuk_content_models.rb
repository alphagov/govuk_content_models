require "govuk_content_models/version"
require "mongoid"
require "mongoid/monkey_patches"
require "govuk_content_models/presentation_toggles"
require "govuk_content_models/action_processors"

module GovukContentModels
  if defined?(Rails)
    class Engine < Rails::Engine
      config.autoload_paths << File.expand_path('govuk_content_models/action_processors', __FILE__)
    end
  end
end
