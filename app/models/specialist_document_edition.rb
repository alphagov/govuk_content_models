require "state_machine"

class SpecialistDocumentEdition
  include Mongoid::Document
  include Mongoid::Timestamps

  field :document_id,          type: String
  field :version_number,       type: Integer,  default: 1

  field :title,                type: String
  field :created_at,           type: DateTime, default: lambda { Time.zone.now }
  field :slug,                 type: String

  field :summary, type: String
  field :body, type: String
  field :opened_date, type: Date
  field :closed_date, type: Date
  field :case_type, type: String
  field :case_state, type: String
  field :market_sector, type: String
  field :outcome_type, type: String

  field :state, type: String

  embeds_many :attachments, cascade_callbacks: true

  state_machine initial: :draft do
    event :publish do
      transition draft: :published
    end

    event :archive do
      transition all => :archived, :unless => :archived?
    end
  end

  GOVSPEAK_FIELDS = [:body]

  def whole_body
    self.body
  end

  scope :draft,               where(state: "draft")
  scope :published,           where(state: "published")
  scope :archived,            where(state: "archived")

  validates :title, presence: true
  validates :summary, presence: true
  validates :body, presence: true
  validates :opened_date, presence: true
  validates :market_sector, presence: true
  validates :case_type, presence: true
  validates :case_state, presence: true
  validates :version_number, presence: true
  validates :document_id, presence: true
  validates_with SafeHtml

  index "document_id"
  index "state"

  def series
    ::SpecialistDocumentEdition.where(document_id: document_id)
  end

  def siblings
    series.excludes(id: id)
  end

  def previous_siblings
    siblings.where(:version_number.lt => version_number)
  end

  def subsequent_siblings
    siblings.where(:version_number.gt => version_number)
  end

  def latest_edition?
    subsequent_siblings.empty?
  end

  def build_attachment(attributes)
    attachments.build(attributes.merge(
      filename: attributes.fetch(:file).original_filename
    ))
  end
end
