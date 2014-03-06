require 'attachable'

class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Attachable

  field :title
  field :filename
  attaches :file

  validates_with SafeHtml

  def snippet
    "[InlineAttachment:#{filename}]"
  end
end
