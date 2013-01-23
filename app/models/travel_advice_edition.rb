require 'parted'
require 'state_machine'
require 'safe_html'

class TravelAdviceEdition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Parted

  field :country_slug,         type: String
  field :title,                type: String
  field :overview,             type: String
  field :version_number,       type: Integer
  field :state,                type: String,    default: "draft"

  embeds_many :actions

  index [[:country_slug, Mongo::ASCENDING], [:version_number, Mongo::DESCENDING]], :unique => true

  GOVSPEAK_FIELDS = []

  before_validation :populate_version_number, :on => :create

  validates_presence_of :country_slug
  validate :state_for_slug_unique
  validates :version_number, :presence => true, :uniqueness => { :scope => :country_slug }
  validate :state_if_modified
  validates_with SafeHtml

  scope :published, where(:state => "published")

  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = [:title, :country_slug, :overview]

  state_machine initial: :draft do
    before_transition :draft => :published do |edition, transition|
      edition.class.where(country_slug: edition.country_slug, state: 'published').each do |ed|
        ed.archive
      end
    end

    event :publish do
      transition draft: :published
    end

    event :archive do
      transition all => :archived, :unless => :archived?
    end
  end

  def indexable_content
    parts.map do |part|
      [part.title, Govspeak::Document.new(part.body).to_text]
    end.flatten.join(" ").strip
  end

  def build_clone
    new_edition = self.class.new
    self.class.fields_to_clone.each do |attr|
      new_edition[attr] = self.read_attribute(attr)
    end
    new_edition.parts = self.parts.map(&:dup)
    new_edition
  end

  def create_action_as(user, action_type, comment = nil)
    actions.create(:requester => user, :request_type => action_type, :comment => comment)
  end

  def publish_as(user)
    publish && create_action_as(user, Action::PUBLISH)
  end

  private

  def state_for_slug_unique
    if %w(published draft).include?(self.state) and
        self.class.where(:_id.ne => id,
                         :country_slug => country_slug,
                         :state => state).any?
      errors.add(:state, :taken)
    end
  end

  def populate_version_number
    if self.version_number.nil? and ! self.country_slug.nil? and ! self.country_slug.empty?
      if latest_edition = self.class.where(:country_slug => self.country_slug).order_by([:version_number, :desc]).first
        self.version_number = latest_edition.version_number + 1
      else
        self.version_number = 1
      end
    end
  end

  def state_if_modified
    unless self.draft? or self.new_record? or self.changed == ['state']
      errors.add(:state, "must be draft to modify")
    end
  end

end
