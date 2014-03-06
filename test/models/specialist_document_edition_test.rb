# encoding: UTF-8

require "test_helper"

class SpecialistDocumentEditionTest < ActiveSupport::TestCase
  def basic_edition_fields
    {
      slug: 'cma-cases/merger-investigation-2014',
      title: "Merger Investigation 2014",
      summary: "This is the summary of stuff going on in the Merger Investigation 2014",
      state: "published",
      body: "A body",
      opened_date: '2012-04-21',
      document_id: 'a-document-id',
      market_sector: 'oil-and-gas',
      case_type: 'some-case-type',
      case_state: 'open'
    }
  end

  should "have correct fields" do
    edition = SpecialistDocumentEdition.new(basic_edition_fields)

    assert_equal basic_edition_fields[:title], edition.title
  end

  should "be persistable" do
    edition = SpecialistDocumentEdition.create!(basic_edition_fields)

    found = SpecialistDocumentEdition.where(slug: edition.slug).first
    assert_equal found.attributes, edition.attributes
  end

  should "build attachments" do
    edition = SpecialistDocumentEdition.new
    file = OpenStruct.new(original_filename: "document.pdf")

    edition.build_attachment(title: "baz", file: file)

    attachment = edition.attachments.first
    assert_equal "baz", attachment.title
    assert_equal "document.pdf", attachment.filename
    assert_equal file, attachment.instance_variable_get(:@file_file)
  end

  should "be able to persist attachment" do
    edition = SpecialistDocumentEdition.new(basic_edition_fields)
    file = OpenStruct.new(original_filename: "document.pdf")

    edition.build_attachment(title: "baz", file: file)
    edition.save!

    found = SpecialistDocumentEdition.where(slug: edition.slug).first

    assert_equal 1, found.attachments.count
    assert_equal "baz", found.attachments.first.title
  end
end

