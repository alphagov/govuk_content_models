class ArtefactExternalLink
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field "title", type: String
  field "url", type: String

  GOVSPEAK_FIELDS = []

  embedded_in :artefact

  validates_with SafeHtml

  validates_presence_of :title
  validates :url, :presence => true, :format => { :with => URI::regexp(%w{http https}) }
end
