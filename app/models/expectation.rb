class Expectation
  include Mongoid::Document
  cache

  field :css_class, type: String
  field :text,      type: String

  validates_with SafeHtml
end
