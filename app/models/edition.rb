require "plek"
require "workflow"

class Edition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Workflow

  field :panopticon_id,        type: String
  field :version_number,       type: Integer,  default: 1
  field :sibling_in_progress,  type: Integer,  default: nil
  field :business_proposition, type: Boolean,  default: false

  field :title,                type: String
  field :created_at,           type: DateTime, default: lambda { Time.now }
  field :overview,             type: String
  field :alternative_title,    type: String
  field :slug,                 type: String
  field :section,              type: String
  field :department,           type: String
  field :rejected_count,       type: Integer,  default: 0
  field :tags,                 type: String

  field :assignee,             type: String
  field :creator,              type: String
  field :publisher,            type: String
  field :archiver,             type: String

  belongs_to :assigned_to, class_name: "User"

  scope :lined_up,            where(state: "lined_up")
  scope :draft,               where(state: "draft")
  scope :amends_needed,       where(state: "amends_needed")
  scope :in_review,           where(state: "in_review")
  scope :fact_check,          where(state: "fact_check")
  scope :fact_check_received, where(state: "fact_check_received")
  scope :ready,               where(state: "ready")
  scope :published,           where(state: "published")
  scope :archived,            where(state: "archived")
  scope :in_progress,         where(:state.nin => ["archived", "published"])
  scope :assigned_to,         lambda { |user| user.nil? ? where(:assigned_to_id.exists => false) : where(assigned_to_id: user.id) }

  validates :title, presence: true
  validates :version_number, presence: true #, uniqueness: {:scope => :panopticon_id}
  validates :panopticon_id, presence: true

  before_destroy :destroy_artefact

  index "assigned_to_id"
  index "panopticon_id"
  index "state"

  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = []

  alias_method :admin_list_title, :title

  def series
    Edition.where(panopticon_id: panopticon_id)
  end

  def history
    series.order([:version_number, :desc])
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

  def published_edition
    series.where(state: "published").order(version_number: "desc").first
  end

  def previous_published_edition
    series.where(state: "published").order(version_number: "desc").second
  end

  def can_create_new_edition?
    subsequent_siblings.in_progress.empty?
  end

  def meta_data
    PublicationMetadata.new self
  end

  def fact_check_email_address
    "factcheck+#{Plek.current.environment}-#{id}@alphagov.co.uk"
  end

  def get_next_version_number
    latest_version = series.order(version_number: "desc").first.version_number
    latest_version + 1
  end

  def build_clone(edition_class=nil)
    raise "Cloning of non published edition not allowed" if self.state != "published"

    edition_class = self.class if edition_class.nil?
    new_edition = edition_class.new(title: self.title, version_number: get_next_version_number)

    # If the new clone is of the same type, we can copy all its fields over; if
    # we are changing the type of the edition, any fields other than the base
    # fields will likely be meaningless.
    if edition_class == self.class
      fields_to_clone = self.class.fields_to_clone
    else
      fields_to_clone = []
    end

    real_fields_to_merge = fields_to_clone + [:panopticon_id, :overview, :alternative_title, :slug, :section, :department]
    real_fields_to_merge.each do |attr|
      new_edition.send("#{attr}=", read_attribute(attr))
    end
    new_edition
  end

  def self.find_or_create_from_panopticon_data(panopticon_id, importing_user, api_credentials)
    existing_publication = Edition.where(panopticon_id: panopticon_id).order_by([:version_number, :desc]).first
    return existing_publication if existing_publication

    raise "Artefact not found" unless metadata = Artefact.find(panopticon_id)

    importing_user.create_edition(metadata.kind.to_sym,
      panopticon_id: metadata.id,
      slug: metadata.slug,
      title: metadata.name,
      section: metadata.primary_section ? metadata.primary_section.title : nil,
      department: metadata.department,
      business_proposition: metadata.business_proposition ? metadata.business_proposition : false)
  end

  def self.find_and_identify(slug, edition)
    scope = where(slug: slug)

    if edition.present? and edition == "latest"
      scope.order_by(:version_number).last
    elsif edition.present?
      scope.where(version_number: edition).first
    else
      scope.where(state: "published").order_by(:created_at).last
    end
  end

  def panopticon_uri
    Plek.current.find("arbiter") + "/artefacts/" + (panopticon_id || slug).to_s
  end

  def format
    self.class.to_s.gsub("Edition", "")
  end

  def format_name
    format
  end

  def has_video?
    false
  end

  def safe_to_preview?
    true
  end

  def has_sibling_in_progress?
    ! sibling_in_progress.nil?
  end

  # stop broadcasting a delete message unless there are no siblings
  def broadcast_action(callback_action)
    super(callback_action) unless (callback_action == "destroyed" and self.siblings.any?)
  end

  def was_published
    previous_siblings.all.each(&:archive)
    notify_siblings_of_published_edition
  end

  def update_from_artefact(artefact)
    self.title = artefact.name unless published?
    self.slug = artefact.slug
    self.section = artefact.section
    self.department = artefact.department
    self.business_proposition = artefact.business_proposition
    self.save!
  end

  def destroy_artefact
    if can_destroy?
      Artefact.find(self.panopticon_id).destroy
    end
  end
end
