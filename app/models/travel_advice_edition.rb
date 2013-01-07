require 'state_machine'

class TravelAdviceEdition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Parted

  field :country_slug,         type: String
  field :version_number,       type: Integer
  field :state,                type: String,    default: "draft"

  index [[:country_slug, Mongo::ASCENDING], [:version_number, Mongo::DESCENDING]], :unique => true

  before_validation :populate_version_number, :on => :create

  validates_presence_of :country_slug
  validate :state_for_slug_unique
  validates :version_number, :presence => true, :uniqueness => { :scope => :country_slug }

  state_machine initial: :draft do
    event :publish do
      transition draft: :published 
    end

    event :archive do
      transition all => :archived, :unless => :archived?
    end
  end

  private

  def state_for_slug_unique
    if %w(published draft).include?(self.state) and 
        self.class.where(:id.ne => _id,
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
end
