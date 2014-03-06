require "test_helper"
require "ostruct"

class AttachmentTest < ActiveSupport::TestCase
  should "generate a snippet" do
    attachment = Attachment.new(
      title: "Supporting attachment",
      filename: "document.pdf"
    )
    expected_snippet = "[InlineAttachment:document.pdf]"

    assert_equal expected_snippet, attachment.snippet
  end
end
