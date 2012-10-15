class Expectation
  include Mongoid::Document
  cache

  field :text,      type: String

  validates_with SafeHtml, govspeak_fields: []
end
