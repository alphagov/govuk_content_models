require "test_helper"
require "fixtures/specialist_document_fixtures"

class RenderedSpecialistDocumentTest < ActiveSupport::TestCase
  include SpecialistDocumentFixtures

  test "can assign all attributes" do
    r = RenderedSpecialistDocument.new(basic_specialist_document_fields)
    basic_specialist_document_fields.each do |k,v|
      if (k =~ /date$/)
        assert_equal Date.parse(v), r.send(k.to_sym)
      else
        assert_equal v, r.send(k.to_sym)
      end
    end
  end

  test "can persist" do
    r = RenderedSpecialistDocument.new(basic_specialist_document_fields)
    r.save!

    assert_equal 1, RenderedSpecialistDocument.where(slug: r.slug).count
  end

  test "duplicate slugs disallowed" do
    RenderedSpecialistDocument.create(slug: "my-slug")
    second = RenderedSpecialistDocument.create(slug: "my-slug")

    refute second.valid?
    assert_equal 1, RenderedSpecialistDocument.count
  end

  test "has no govspeak fields" do
    assert_equal [], RenderedSpecialistDocument::GOVSPEAK_FIELDS
  end

  test "can store headers hash" do
    sample_headers = [
      {
        "text" => "Phase 1",
        "level" => 2,
        "id" => "phase-1",
        "headers" => []
      }
    ]
    sample_fields = basic_specialist_document_fields.merge(headers: sample_headers)
    r = RenderedSpecialistDocument.create!(sample_fields)

    found = RenderedSpecialistDocument.where(slug: r.slug).first
    assert_equal sample_headers, found.headers
  end
end
