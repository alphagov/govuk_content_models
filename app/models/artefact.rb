require "slug_validator"
require "tag_repository"
require "plek"
require "taggable"
require "artefact_action"  # Require this when running outside Rails

class CannotEditSlugIfEverPublished < ActiveModel::Validator
  def validate(record)
    if record.changes.keys.include?("slug") && record.live_was == true
      record.errors[:slug] << ("Cannot edit slug for live artefacts")
    end
  end
end

class Artefact
  include Mongoid::Document
  include Mongoid::Timestamps

  include Taggable
  stores_tags_for :sections, :writing_teams, :propositions, :keywords
  has_primary_tag_for :section

  # NOTE: these fields are deprecated, and soon to be replaced with a
  # tag-based implementation
  field "department",           type: String
  field "business_proposition", type: Boolean, default: false

  field "name",                 type: String
  field "slug",                 type: String
  field "paths",                type: Array, default: []
  field "prefixes",             type: Array, default: []
  field "kind",                 type: String
  field "owning_app",           type: String
  field "rendering_app",        type: String
  field "active",               type: Boolean, default: false
  field "need_id",              type: String
  field "fact_checkers",        type: String
  field "relatedness_done",     type: Boolean, default: false
  field "publication_id",       type: String
  field "description",          type: String
  field "live",                 type: Boolean, default: false
  field "specialist_body",      type: String

  MAXIMUM_RELATED_ITEMS = 8

  FORMATS = [
    "answer",
    "guide",
    "programme",
    "local_transaction",
    "transaction",
    "place",
    "smart-answer",
    "custom-application",
    "licence",
    "business_support"
  ].freeze

  KIND_TRANSLATIONS = {
    "standard transaction link"        => "transaction",
    "local authority transaction link" => "local_transaction",
    "benefit / scheme"                 => "programme",
    "find my nearest"                  => "place",
  }.tap { |h| h.default_proc = -> _, k { k } }.freeze

  has_and_belongs_to_many :related_artefacts, class_name: "Artefact"
  belongs_to :contact
  embeds_many :actions, class_name: "ArtefactAction", order: :created_at

  before_validation :normalise, on: :create
  before_create :record_create_action
  before_update :record_update_action
  after_update :update_editions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, slug: true
  validates :kind, inclusion: { in: FORMATS }
  validates :owning_app, presence: true
  validates_with CannotEditSlugIfEverPublished

  def self.in_alphabetical_order
    order_by([[:name, :asc]])
  end

  def self.find_by_slug(s)
    where(slug: s).first
  end

  # The old-style section string identifier, of the form 'Crime:Prisons'
  def section
    return '' unless self.primary_section
    if primary_section.parent
      [primary_section.parent.title, primary_section.title].join ':'
    else
      primary_section.title
    end
  end

  def normalise
    return unless kind.present?
    self.kind = KIND_TRANSLATIONS[kind.to_s.downcase.strip]
  end

  def admin_url(options = {})
    [ "#{Plek.current.find(owning_app)}/admin/publications/#{id}",
      options.to_query
    ].reject(&:blank?).join("?")
  end

  # TODO: Replace this nonsense with a proper API layer.
  def as_json(options={})
    super(options.merge(
      include: {contact: {}}
    )).tap { |hash|
      if hash["tag_ids"]
        hash["tag_ids"] = hash["tag_ids"].map { |tag_id| TagRepository.load(tag_id).as_json }
      else
        hash.delete "tag_ids"
      end
      
      if self.primary_section
        hash['primary_section'] = self.primary_section.tag_id
      end
      
      unless options[:ignore_related_artefacts]
        hash["related_items"] = published_related_artefacts.map { |a| {"artefact" => a.as_json(ignore_related_artefacts: true)} }
      end
      hash.delete("related_artefacts")
      hash.delete("related_artefact_ids")
      hash["id"] = hash.delete("_id")
      hash["contact"]["id"] = hash["contact"].delete("_id") if hash["contact"]

      # Add a section identifier if needed
      hash["section"] ||= section
    }
  end

  def published_related_artefacts
    related_artefacts.select do |related_artefact|
      if related_artefact.owning_app == "publisher"
        related_artefact.any_editions_published?
      else
        true
      end
    end
  end

  def any_editions_published?
    Edition.where(panopticon_id: self.id, state: 'published').any?
  end

  def any_editions_ever_published?
    Edition.where(panopticon_id: self.id, :state.in => ['published', 'archived']).any?
  end

  def update_editions
    Edition.where(:state.nin => ["archived"], panopticon_id: self.id).each do |edition|
      edition.update_from_artefact(self)
    end
  end

  def self.from_param(slug_or_id)
    # FIXME: A hack until the Publisher has panopticon ids for every article
    find_by_slug(slug_or_id) || find(slug_or_id)
  rescue BSON::InvalidObjectId
    raise Mongoid::Errors::DocumentNotFound.new(self, slug_or_id)
  end

  def update_attributes_as(user, *args)
    assign_attributes(*args)
    save_as user
  end

  def save_as(user, options={})
    default_action = new_record? ? "create" : "update"
    action_type = options.delete(:action_type) || default_action
    record_action action_type, user: user
    save(options)
  end

  def record_create_action
    record_action "create"
  end

  def record_update_action
    record_action "update"
  end

  def record_action(action_type, options={})
    user = options[:user]
    current_snapshot = snapshot
    last_snapshot = actions.last ? actions.last.snapshot : nil
    unless current_snapshot == last_snapshot
      new_action = actions.build(
        user: user,
        action_type: action_type,
        snapshot: current_snapshot
      )
      # Mongoid will not fire creation callbacks on embedded documents, so we
      # need to trigger this manually. There is a `cascade_callbacks` option on
      # `embeds_many`, but it doesn't appear to trigger creation events on
      # children when an update event fires on the parent
      new_action.set_created_at
    end
  end

  def snapshot
    reconcile_tag_ids
    attributes.except "_id", "created_at", "updated_at", "actions"
  end
end
