require "safe_html"
require 'govspeak_smart_quotes_fixer'

class Part
  include Mongoid::Document

  embedded_in :guide_edition
  embedded_in :programme_edition
  embedded_in :business_support_edition

  field :order,      type: Integer
  field :title,      type: String
  field :body,       type: String
  field :slug,       type: String
  field :created_at, type: DateTime, default: lambda { Time.zone.now }

  default_scope asc(:order)

  GOVSPEAK_FIELDS = [:body]

  include GovspeakSmartQuotesFixer

  validates_presence_of :title
  validates_presence_of :slug
  validates_exclusion_of :slug, in: ["video"], message: "Can not be video"
  validates_format_of :slug, with: /^[a-z0-9\-]+$/i
  validates_with SafeHtml
end
