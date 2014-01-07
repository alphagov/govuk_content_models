require "slug_validator"
require "plek"
require "traits/taggable"
require "artefact_action"  # Require this when running outside Rails
require "safe_html"

class CannotEditSlugIfEverPublished < ActiveModel::Validator
  def validate(record)
    if record.changes.keys.include?("slug") && record.state_was == "live"
      record.errors[:slug] << ("Cannot edit slug for live artefacts")
    end
  end
end

class Artefact
  include Mongoid::Document
  include Mongoid::Timestamps

  include Taggable
  stores_tags_for :sections, :writing_teams, :propositions,
                  :keywords, :legacy_sources, :industry_sectors
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
  field "publication_id",       type: String
  field "description",          type: String
  field "state",                type: String,  default: "draft"
  field "specialist_body",      type: String
  field "language",             type: String,  default: "en"
  field "need_extended_font",   type: Boolean, default: false

  index "slug", :unique => true

  # This index allows the `relatable_artefacts` method to use an index-covered
  # query, so it doesn't have to load each of the artefacts.
  index [[:name, Mongo::ASCENDING],
         [:state, Mongo::ASCENDING],
         [:kind, Mongo::ASCENDING],
         [:_type, Mongo::ASCENDING],
         [:_id, Mongo::ASCENDING]]

  scope :not_archived, where(:state.nin => ["archived"])

  GOVSPEAK_FIELDS = []

  validates_with SafeHtml

  MAXIMUM_RELATED_ITEMS = 8

  FORMATS_BY_DEFAULT_OWNING_APP = {
    "publisher"               => ["answer",
                                  "business_support",
                                  "campaign",
                                  "completed_transaction",
                                  "guide",
                                  "help_page",
                                  "licence",
                                  "local_transaction",
                                  "place",
                                  "programme",
                                  "simple_smart_answer",
                                  "transaction",
                                  "video"],
    "smartanswers"            => ["smart-answer"],
    "custom-application"      => ["custom-application"], # In this case the owning_app is overriden. eg calendars, licencefinder
    "travel-advice-publisher" => ["travel-advice"],
    "whitehall"               => ["case_study",
                                  "consultation",
                                  "detailed_guide",
                                  "news_article",
                                  "speech",
                                  "policy",
                                  "publication",
                                  "statistical_data_set",
                                  "worldwide_priority"]
  }.freeze

  FORMATS = FORMATS_BY_DEFAULT_OWNING_APP.values.flatten

  def self.default_app_for_format(format)
    FORMATS_BY_DEFAULT_OWNING_APP.detect { |app, formats| formats.include?(format) }.first
  end

  KIND_TRANSLATIONS = {
    "standard transaction link"        => "transaction",
    "local authority transaction link" => "local_transaction",
    "completed/done transaction" => "completed_transaction",
    "benefit / scheme"                 => "programme",
    "find my nearest"                  => "place",
  }.tap { |h| h.default_proc = -> _, k { k } }.freeze

  has_and_belongs_to_many :related_artefacts, class_name: "Artefact"
  embeds_many :actions, class_name: "ArtefactAction", order: :created_at

  embeds_many :external_links, class_name: "ArtefactExternalLink"
  accepts_nested_attributes_for :external_links, :allow_destroy => true,
    reject_if: proc { |attrs| attrs["title"].blank? && attrs["url"].blank?  }

  before_validation :normalise, on: :create
  before_create :record_create_action
  before_update :record_update_action
  after_update :update_editions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, slug: true
  validates :kind, inclusion: { in: lambda { |x| FORMATS } }
  validates :state, inclusion: { in: ["draft", "live", "archived"] }
  validates :owning_app, presence: true
  validates :language, inclusion: { in: ["en", "cy"] }
  validates_with CannotEditSlugIfEverPublished
  validate :validate_prefixes_and_paths

  def self.in_alphabetical_order
    order_by([[:name, :asc]])
  end

  def self.find_by_slug(s)
    where(slug: s).first
  end

  def self.relatable_items
    # Only retrieving the name field, because that's all we use in Panopticon's
    # helper method (the only place we use this), and it means the index can
    # cover the query entirely
    self.in_alphabetical_order
        .where(:kind.ne => "completed_transaction", :state.ne => "archived")
        .only(:name)
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

  # Fallback to english if no language is present
  def language
    attributes['language'] || "en"
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
    super.tap { |hash|
      if hash["tag_ids"]
        hash["tags"] = Tag.by_tag_ids!(hash["tag_ids"]).map(&:as_json)
      else
        hash["tag_ids"] = []
        hash["tags"] = []
      end

      if self.primary_section
        hash['primary_section'] = self.primary_section.tag_id
      end

      unless options[:ignore_related_artefacts]
        hash["related_items"] = published_related_artefacts.map do |a|
          {"artefact" => a.as_json(ignore_related_artefacts: true)}
        end
      end
      hash.delete("related_artefacts")
      hash.delete("related_artefact_ids")
      hash["id"] = hash.delete("_id")

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

  # Pass in the desired scope, eg self.related_artefacts.live,
  # get back the items in the order they were set in, rather than natural order
  def ordered_related_artefacts(scope_or_array = self.related_artefacts)
    scope_or_array.sort_by { |artefact| related_artefact_ids.index(artefact.id) }
  end

  def related_artefacts_grouped_by_distance(scope_or_array = self.related_artefacts)
    groups = { "subsection" => [], "section" => [], "other" => [] }
    scoped_artefacts = ordered_related_artefacts(scope_or_array)

    if primary_tag = self.primary_section
      groups['subsection'] = scoped_artefacts.select {|a| a.tag_ids.include?(primary_tag.tag_id) }

      if primary_tag.parent_id.present?
        pattern = Regexp.new "^#{Regexp.quote(primary_tag.parent_id)}\/.+"
        groups['section'] = scoped_artefacts.reject {|a| groups['subsection'].include?(a) }.select {|a|
          a.tag_ids.grep(pattern).count > 0
        }
      end
    end
    groups['other'] = scoped_artefacts.reject {|a| (groups['subsection'] + groups['section']).include?(a) }

    groups
  end

  def any_editions_published?
    Edition.where(panopticon_id: self.id, state: 'published').any?
  end

  def any_editions_ever_published?
    Edition.where(panopticon_id: self.id,
                  :state.in => ['published', 'archived']).any?
  end

  def update_editions
    if state != 'archived'
      Edition.where(:state.nin => ["archived"],
                    panopticon_id: self.id).each do |edition|
        edition.update_from_artefact(self)
      end
    else
      archive_editions
    end
  end

  def archive_editions
    if state == 'archived'
      Edition.where(panopticon_id: self.id, :state.nin => ["archived"]).each do |edition|
        edition.new_action(self, "note", comment: "Artefact has been archived. Archiving this edition.")
        edition.archive!
      end
    end
  end

  def self.from_param(slug_or_id)
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

  def archived?
    self.state == "archived"
  end

  def live?
    self.state == "live"
  end

  def snapshot
    reconcile_tag_ids
    attributes.except "_id", "created_at", "updated_at", "actions"
  end

  private

  def validate_prefixes_and_paths
    if ! self.prefixes.nil? and self.prefixes_changed?
      if self.prefixes.any? {|p| ! valid_url_path?(p)}
        errors.add(:prefixes, "are not all valid absolute URL paths")
      end
    end
    if ! self.paths.nil? and self.paths_changed?
      if self.paths.any? {|p| ! valid_url_path?(p)}
        errors.add(:paths, "are not all valid absolute URL paths")
      end
    end
  end

  def valid_url_path?(path)
    return false unless path.starts_with?("/")
    uri = URI.parse(path)
    uri.path == path && path !~ %r{//} && path !~ %r{./\z}
  rescue URI::InvalidURIError
    false
  end
end
