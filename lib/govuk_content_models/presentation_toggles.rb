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
    presentation_toggles['organ_donor_registration']
  end

  module ClassMethods
    def default_presentation_toggles
      {
        'organ_donor_registration' =>
          { 'promote_organ_donor_registration' => false, 'organ_donor_registration_url' => '' }
      }
    end
  end
end
