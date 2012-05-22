require "parted"
require "whole_edition"

class LicenceEdition < WholeEdition
  include Parted

  def safe_to_preview?
    parts.any? and parts.first.slug.present?
  end
end
