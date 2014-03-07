require "test_helper"
require "ostruct"
require 'gds_api/test_helpers/asset_manager'

class AttachmentTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::AssetManager

  setup do
    @original_asset_api_client = Attachable.asset_api_client
    Attachable.asset_api_client = stub("asset_api_client")
  end

  teardown do
    Attachable.asset_api_client = @original_asset_api_client
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
    attachment = Attachment.new(
      title: "Photo of me",
      filename: "photo.jpg",
      file_id: "test-id"
    )

    asset_url = stub("asset url")
    asset_response = stub("asset response", file_url: asset_url)
    Attachable.asset_api_client
      .stubs(:asset)
      .with(attachment.file_id)
      .returns(asset_response)

    assert_equal asset_url, attachment.url
  end
end
