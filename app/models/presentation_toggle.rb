class PresentationToggle
  include Mongoid::Document

  embedded_in :completed_transaction_edition

  field :url, type: String
  field :display, type: Boolean, default: false

  validates_presence_of :url, if: :display?
end
