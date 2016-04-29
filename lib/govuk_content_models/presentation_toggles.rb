module PresentationToggles
  extend ActiveSupport::Concern

  included do
    field :presentation_toggles, type: Hash, default: default_presentation_toggles
    validates_presence_of :organ_donor_registration_url, if: :promote_organ_donor_registration?
    validates :promotion_choice_url, presence: true, if: :promotes_something?
    validates :promotion_choice, inclusion: { in: %w(none organ_donor register_to_vote) }
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
    unless presentation_toggles.key? 'organ_donor_registration'
      presentation_toggles['organ_donor_registration'] = self.class.default_presentation_toggles['organ_donor_registration']
    end
    presentation_toggles['organ_donor_registration']
  end

  def promotion_choice=(value)
    promotion_choice_key["choice"] = value
  end

  def promotion_choice_url=(value)
    promotion_choice_key['url'] = value
  end

  def promotion_choice
    has_legacy_promote = promote_organ_donor_registration
    choice = promotion_choice_key["choice"]
    if choice.empty?
      if has_legacy_promote
        "organ_donor"
      else
        "none"
      end
    else
      choice
    end
  end

  def promotes_something?
    promotion_choice != 'none'
  end

  def promotion_choice_url
    url = promotion_choice_key["url"]
    url.empty? ? organ_donor_registration_url : url
  end

  def promotion_choice_key
    unless presentation_toggles.key? 'promotion_choice'
      presentation_toggles['promotion_choice'] = self.class.default_presentation_toggles['promotion_choice']
    end
    presentation_toggles['promotion_choice']
  end

  module ClassMethods
    def default_presentation_toggles
      {
        'organ_donor_registration' =>
          {
            'promote_organ_donor_registration' => false,
            'organ_donor_registration_url' => ''
          },
        'promotion_choice' =>
          {
            'choice' => '',
            'url' => ''
          }
      }
    end
  end
end
