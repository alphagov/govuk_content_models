# encoding: UTF-8

require "test_helper"

class SpecialistDocumentEditionTest < ActiveSupport::TestCase
  should "have correct fields" do
    fields = {
      slug: 'cma-cases/merger-investigation-2014',
      title: "Merger Investigation 2014",
      summary: "This is the summary of stuff going on in the Merger Investigation 2014",
      state: "published"
    }

    edition = SpecialistDocumentEdition.new(fields)

    assert_equal fields[:title], edition.title
  end

  should "be persistable" do
    edition = SpecialistDocumentEdition.create!(
      slug: 'cma-cases/merger-investigation-2014',
      title: "Merger Investigation 2014",
      summary: "This is the summary of stuff going on in the Merger Investigation 2014",
      state: "published",
      document_id: 'a-document-id'
    )

    found = SpecialistDocumentEdition.where(slug: edition.slug).first
    assert_equal found.attributes, edition.attributes
  end
end

