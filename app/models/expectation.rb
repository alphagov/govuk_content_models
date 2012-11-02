class Expectation
  include Mongoid::Document
  cache

  field :text,      type: String

  GOVSPEAK_FIELDS = []

  validates_with SafeHtml
end
