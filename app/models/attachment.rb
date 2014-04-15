require 'attachable'

class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Attachable

  field :title
  field :filename
  attaches :file, with_url_field: true, update_existing: true

  embedded_in :specialist_document_edition

  validates_with SafeHtml

  # TODO: Move this to a domain object in specialist publisher
  def snippet
    "[InlineAttachment:#{filename}]"
  end
end
