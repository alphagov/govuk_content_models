class TravelAdviceEdition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Parted

  field :country_slug,         type: String
  field :version_number,       type: Integer,   default: 1
  field :sibling_in_progress,  type: Integer,   default: nil
  field :state,                type: String,    default: "draft"

  validates_presence_of :country_slug
  validates_uniqueness_of :country_slug

  state_machine initial: :draft do
    event :publish do
      transition draft: :published 
    end

    event :archive do
      transition all => :archived, :unless => :archived?
    end
  end

end
