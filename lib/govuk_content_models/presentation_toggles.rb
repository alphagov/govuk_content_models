module PresentationToggles
  extend ActiveSupport::Concern

  included do
    field :presentation_toggles, type: Hash, default: default_presentation_toggles
    validates_presence_of :organ_donor_registration_url, if: :promote_organ_donor_registration?
  end

  def promote_organ_donor_registration=(value)
    value = value.is_a?(Boolean) ? value : value != '0' # if assigned using a checkbox
    organ_donor_registration_key['promote_organ_donor_registration'] = value
  end

  def promote_organ_donor_registration
    organ_donor_registration_key['promote_organ_donor_registration']
  end
  alias_method :promote_organ_donor_registration?, :promote_organ_donor_registration

  def organ_donor_registration_url=(value)
    organ_donor_registration_key['organ_donor_registration_url'] = value
  end
  
  def organ_donor_registration_url
    organ_donor_registration_key['organ_donor_registration_url']
  end

  def organ_donor_registration_key
    presentation_toggles['organ_donor_registration'] || self.class.default_presentation_toggles['organ_donor_registration']
  end

  def promote_register_to_vote=(value)
    value = value.is_a?(Boolean) ? value : value != '0' # if assigned using a checkbox
    register_to_vote_key['promote_register_to_vote'] = value
  end

  def promote_register_to_vote
    register_to_vote_key['promote_register_to_vote']
  end
  alias_method :promote_register_to_vote?, :promote_register_to_vote

  def register_to_vote_url=(value)
    register_to_vote_key['register_to_vote_url'] = value
  end
  
  def register_to_vote_url
    register_to_vote_key['register_to_vote_url']
  end

  def register_to_vote_key
    presentation_toggles['register_to_vote'] || self.class.default_presentation_toggles['register_to_vote']
  end

  module ClassMethods
    def default_presentation_toggles
      {
        'organ_donor_registration' =>
          { 'promote_organ_donor_registration' => false, 'organ_donor_registration_url' => '' },
        'register_to_vote' =>
          { 'promote_register_to_vote' => false, 'register_to_vote_url' => '' },
      }
    end
  end
end
