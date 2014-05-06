class ManualEdition
  include Mongoid::Document
  include Mongoid::Timestamps

  field :manual_id, type: String
  field :version_number, type: Integer, default: 1

  field :title, type: String
  field :created_at, type: DateTime, default: lambda { Time.zone.now }
  field :state, type: String, default: 'draft'

  field :summary, type: String

  validates_with SafeHtml
end
