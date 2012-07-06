require "govuk_content_models/version"
require "mongoid"

begin
  module GovukContentModels
    class Engine < Rails::Engine
    end
  end
rescue NameError
  module GovukContentModels
  end
end