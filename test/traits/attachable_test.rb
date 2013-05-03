require 'test_helper'

class MockAssetApi
  class MockError < StandardError; end
end

class ModelWithAttachments
  include Attachable
  include Mongoid::Document

  field :title, type: String
  attaches :image
end

class AttachableTest < ActiveSupport::TestCase

  setup do
    @edition = ModelWithAttachments.new
    @previous_api_client = Attachable.asset_api_client
    Attachable.asset_api_client = MockAssetApi.new
  end

  teardown do
    Attachable.asset_api_client = @previous_api_client
  end

  context "retreiving assets from the api" do
    should "raise an exception if there is no api client present" do
      Attachable.asset_api_client = nil

      @edition.image_id = "an_image_id"
      assert_raise Attachable::ApiClientNotPresent do
        @edition.image.file_url
      end
    end

    should "make the request to the asset api" do
      @edition.image_id = "an_image_id"

      asset = OpenStruct.new(:file_url => "/path/to/image")
      MockAssetApi.any_instance.expects(:asset).with("an_image_id").returns(asset)

      assert_equal "/path/to/image", @edition.image.file_url
    end

    should "cache the asset from the api" do
      @edition.image_id = "an_image_id"

      asset = OpenStruct.new(:something => "one", :something_else => "two")
      MockAssetApi.any_instance.expects(:asset).once.with("an_image_id").returns(asset)

      assert_equal "one", @edition.image.something
      assert_equal "two", @edition.image.something_else
    end

    should "assign a file and detect it has changed" do
      file = File.open(File.expand_path("../../fixtures/uploads/image.jpg", __FILE__))

      @edition.image = file
      assert @edition.image_has_changed?
    end
  end

  context "saving an edition" do
    setup do
      @file = File.open(File.expand_path("../../fixtures/uploads/image.jpg", __FILE__))
      @asset = OpenStruct.new(:id => 'http://asset-manager.dev.gov.uk/assets/an_image_id')
    end

    should "upload the asset" do
      MockAssetApi.any_instance.expects(:create_asset).with({ :file => @file }).returns(@asset)

      @edition.image = @file
      @edition.save!
    end

    should "not upload an asset if it has not changed" do
      ModelWithAttachments.any_instance.expects(:upload_image).never
      @edition.save!
    end

    should "assign the asset id to the attachment id attribute" do
      MockAssetApi.any_instance.expects(:create_asset).with({ :file => @file }).returns(@asset)

      @edition.image = @file
      @edition.save!

      assert_equal "an_image_id", @edition.image_id
    end

    should "raise an exception if there is no api client present" do
      Attachable.asset_api_client = nil

      @edition.image = @file
      assert_raise Attachable::ApiClientNotPresent do
        @edition.save!
      end
    end

    should "catch any errors raised by the api client" do
      MockAssetApi.any_instance.expects(:create_asset).raises(MockAssetApi::MockError)

      assert_nothing_raised do
        @edition.image = @file
        @edition.save!
      end

      assert_equal ["could not be uploaded"], @edition.errors[:image_id]
    end

    should "not stop the edition from being saved when an uploading error is raised" do
      MockAssetApi.any_instance.expects(:create_asset).raises(MockAssetApi::MockError)

      @edition.image = @file
      @edition.title = "foo"
      @edition.save!

      @edition.reload
      assert_equal "foo", @edition.title
    end
  end

  context "removing an asset" do
    should "remove an asset when remove_* set to true" do
      @edition.image_id = 'an_image_id'
      @edition.remove_image = true
      @edition.save!

      assert_nil @edition.image_id
    end

    should "not remove an asset when remove_* set to false or empty" do
      @edition.image_id = 'an_image_id'
      @edition.remove_image = false
      @edition.remove_image = ""
      @edition.remove_image = nil
      @edition.save!

      assert_equal "an_image_id", @edition.image_id
    end
  end

end
