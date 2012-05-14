require "bundler/setup"

%w[ app/models app/validators ].each do |path|
  full_path = File.expand_path("../../#{path}", __FILE__)
  $:.unshift full_path unless $:.include?(full_path)
end

require "active_support/test_case"
require "minitest/autorun"
require "fakeweb"
require "mongoid"
