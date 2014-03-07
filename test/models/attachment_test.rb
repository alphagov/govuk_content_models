require "test_helper"
require "ostruct"
require 'gds_api/test_helpers/asset_manager'

class AttachmentTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::AssetManager

  setup do
    Attachable.
  end

  should "generate a snippet" do
    attachment = Attachment.new(
      title: "Supporting attachment",
      filename: "document.pdf"
    )
    expected_snippet = "[InlineAttachment:document.pdf]"

    assert_equal expected_snippet, attachment.snippet
  end

  should "return the url via #url" do
    url = "http://fooey.gov.uk/media/photo.jpg"
    asset_manager_has_an_asset(
      "test-id",
      "name" => "photo.jpg",
      "content_type" => "image/jpeg",
      "file_url" => url,
    )

    attachment = Attachment.new(
      title: "Photo of me",
      filename: "photo.jpg",
    ).tap do |attachment|
      attachment.instance_variable_set(:@file_id, "test-id")
    end

    assert_equal url, attachment.url
  end
end
