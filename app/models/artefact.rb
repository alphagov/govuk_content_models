require "slug_validator"
require "tag_repository"

class Artefact
  include Mongoid::Document
  include Mongoid::Timestamps

  field "section",              type: String
  field "name",                 type: String
  field "slug",                 type: String
  field "kind",                 type: String
  field "owning_app",           type: String
  field "active",               type: Boolean, default: false
  field "tags",                 type: String
  field "need_id",              type: String
  field "department",           type: String
  field "fact_checkers",        type: String
  field "relatedness_done",     type: Boolean, default: false
  field "publication_id",       type: String
  field "business_proposition", type: Boolean, default: false
  field "tag_ids",              type: Array

  MAXIMUM_RELATED_ITEMS = 8

  FORMATS = [
    "answer",
    "guide",
    "programme",
    "local_transaction",
    "transaction",
    "place",
    "smart-answer",
    "custom-application"
  ].freeze

  KIND_TRANSLATIONS = {
    'standard transaction link'        => 'transaction',
    'local authority transaction link' => 'local_transaction',
    'benefit / scheme'                 => 'programme',
    'find my nearest'                  => 'place',
  }.tap { |h| h.default_proc = -> _, k { k } }.freeze

  has_and_belongs_to_many :related_artefacts, :class_name => "Artefact"
  belongs_to :contact

  before_validation :normalise, :on => :create

  validates :name, :presence => true
  validates :slug, :presence => true, :uniqueness => true, :slug => true
  validates :kind, :inclusion => { :in => FORMATS }
  validates_presence_of :owning_app

  before_save :save_section_as_tags

  # TODO: Remove this 'unless' hack after importing. It's only here because
  # some old entries in Panopticon lack a need_id.
  validates_presence_of :need_id, :unless => lambda { defined? IMPORTING_LEGACY_DATA }

  def self.in_alphabetical_order
    order_by([[:name, :asc]])
  end

  def self.find_by_slug(s)
    where(slug: s).first
  end


  def save_section_as_tags
    return if self.section.blank?

    # goes from 'Crime and Justice:The police'
    # to 'crime-and-justice', 'the-police'
    # tag_ids: 'crime-and-justice', 'crime-and-justice/the-police'
    section, sub_section = self.section.downcase.gsub(' ', '-').split(':')

    tag_ids = [section]
    tag_ids.push "#{section}/#{sub_section}" unless sub_section.blank?

    tag_ids.each do |tag_id|
      raise "missing tag #{tag_id}" unless TagRepository.load(tag_id)
    end
    self.tag_ids = tag_ids
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
      if hash['tag_ids']
        hash['tag_ids'] = hash['tag_ids'].map { |tag_id| TagRepository.load(tag_id).as_json }
      else
        hash.delete 'tag_ids'
      end

      unless options[:ignore_related_artefacts]
        hash["related_items"] = related_artefacts.map { |a| {"artefact" => a.as_json(ignore_related_artefacts: true)} }
      end
      hash.delete("related_artefacts")
      hash.delete("related_artefact_ids")
      hash["id"] = hash.delete("_id")
      hash["contact"]["id"] = hash["contact"].delete("_id") if hash["contact"]
    }
  end

  def self.from_param(slug_or_id)
    # FIXME: A hack until the Publisher has panopticon ids for every article
    find_by_slug(slug_or_id) || find(slug_or_id)
  rescue BSON::InvalidObjectId
    raise Mongoid::Errors::DocumentNotFound.new(self, slug_or_id)
  end
end
