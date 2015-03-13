module PresentationToggles
  extend ActiveSupport::Concern

  included do
    field :presentation_toggles, type: Hash, default: default_presentation_toggles
  end

  def display_organ_donor_registration_promotion=(value)
    value = value.is_a?(Boolean) ? value : value != '0' # if assigned using a checkbox
    organ_donor_registration_promotion_key['display'] = value
  end

  def display_organ_donor_registration_promotion
    organ_donor_registration_promotion_key['display']
  end
  alias_method :display_organ_donor_registration_promotion?, :display_organ_donor_registration_promotion

  def organ_donor_registration_promotion_url=(value)
    organ_donor_registration_promotion_key['url'] = value
  end

  def organ_donor_registration_promotion_url
    return "" unless display_organ_donor_registration_promotion?
    organ_donor_registration_promotion_key['url']
  end

  def organ_donor_registration_promotion_key
    presentation_toggles['organ_donor_registration_promotion']
  end

  module ClassMethods
    def default_presentation_toggles
      {
        'organ_donor_registration_promotion' => { 'url' => '', 'display' => false }
      }
    end
  end
end
