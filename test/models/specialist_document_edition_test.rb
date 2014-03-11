# encoding: UTF-8

require "test_helper"
require "fixtures/specialist_document_fixtures"

class SpecialistDocumentEditionTest < ActiveSupport::TestCase
  include SpecialistDocumentFixtures

  setup do
    @original_asset_api_client = Attachable.asset_api_client
    Attachable.asset_api_client = stub("asset_api_client")
  end

  teardown do
    Attachable.asset_api_client = @original_asset_api_client
  end

  should "have correct fields" do
    edition = SpecialistDocumentEdition.new(basic_specialist_document_fields)

    assert_equal basic_specialist_document_fields[:title], edition.title
  end

  should "be persistable" do
    edition = SpecialistDocumentEdition.create!(basic_specialist_document_fields)

    found = SpecialistDocumentEdition.where(slug: edition.slug).first
    assert_equal found.attributes, edition.attributes
  end

  context "building attachments" do
    should "build an attachment" do
      edition = SpecialistDocumentEdition.new
      file = OpenStruct.new(original_filename: "document.pdf")

      edition.build_attachment(title: "baz", file: file)

      attachment = edition.attachments.first
      assert_equal "baz", attachment.title
      assert_equal "document.pdf", attachment.filename
      assert_equal file, attachment.instance_variable_get(:@file_file)
    end

    should "persist attachment record when document saved" do
      Attachable.asset_api_client.stubs(:create_asset)

      edition = SpecialistDocumentEdition.new(basic_specialist_document_fields)
      file = OpenStruct.new(original_filename: "document.pdf")

      edition.build_attachment(title: "baz", file: file)
      edition.save!

      found = SpecialistDocumentEdition.where(slug: edition.slug).first

      assert_equal 1, found.attachments.count
      assert_equal "baz", found.attachments.first.title
    end

    should "transmit attached file to asset manager when document saved" do
      edition = SpecialistDocumentEdition.new(basic_specialist_document_fields)
      file = OpenStruct.new(original_filename: "document.pdf")

      success_response = stub("asset manager response", id: "/test-id")
      Attachable.asset_api_client.expects(:create_asset).with(file: file).returns(success_response)

      edition.build_attachment(title: "baz", file: file)
      edition.save!
    end
  end
end

