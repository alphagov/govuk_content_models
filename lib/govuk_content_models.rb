require "govuk_content_models/version"
require "mongoid"
require "mongoid/monkey_patches"

begin
  module GovukContentModels
    class Engine < Rails::Engine
    end
  end
rescue NameError
  module GovukContentModels
  end
end
