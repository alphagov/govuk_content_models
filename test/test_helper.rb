ENV["RACK_ENV"] = "test"

require "bundler/setup"

%w[ app/models app/validators app/repositories ].each do |path|
  full_path = File.expand_path("../../#{path}", __FILE__)
  $:.unshift full_path unless $:.include?(full_path)
end

require "active_support/test_case"
require "minitest/autorun"
require "fakeweb"
require "mongoid"

Mongoid.load! File.expand_path("../../config/mongoid.yml", __FILE__)
puts "LOADED"
