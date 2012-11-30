require "plek"

class FactCheckAddress
  PREFIX = "factcheck+#{Plek.current.environment}-"
  DOMAIN = "alphagov.co.uk"

  def for_edition(edition)
    "#{PREFIX}#{edition.id}@#{DOMAIN}"
  end

  def regexp
    /#{PREFIX}(.+?)@#{DOMAIN}/
  end
end