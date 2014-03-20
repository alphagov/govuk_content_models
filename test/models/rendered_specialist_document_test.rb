require "test_helper"
require "fixtures/specialist_document_fixtures"

class RenderedSpecialistDocumentTest < ActiveSupport::TestCase
  include SpecialistDocumentFixtures

  def label_fields
    {
      case_type_label: "Some case type",
      case_state_label: "Open",
      market_sector_label: "Oil and gas",
      outcome_type_label: "Referred"
    }
  end

  def rendered_specialist_document_attributes
    basic_specialist_document_fields
      .reject { |k,v| k == :state }
      .merge(label_fields)
  end

  test "can instantiate with basic attributes" do
    r = RenderedSpecialistDocument.new(rendered_specialist_document_attributes)
    rendered_specialist_document_attributes.each do |k,v|
      if (k =~ /date$/)
        assert_equal Date.parse(v), r.public_send(k.to_sym)
      else
        assert_equal v, r.public_send(k.to_sym)
      end
    end
  end

  test "can assign basic attributes" do
    r = RenderedSpecialistDocument.new
    rendered_specialist_document_attributes.each do |k,v|
      r.public_send(:"#{k}=", v)
      if (k =~ /date$/)
        assert_equal Date.parse(v), r.public_send(k.to_sym)
      else
        assert_equal v, r.public_send(k.to_sym)
      end
    end
  end

  test "can persist" do
    r = RenderedSpecialistDocument.new(rendered_specialist_document_attributes)
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
    sample_fields = rendered_specialist_document_attributes.merge(headers: sample_headers)
    r = RenderedSpecialistDocument.create!(sample_fields)

    found = RenderedSpecialistDocument.where(slug: r.slug).first
    assert_equal sample_headers, found.headers
  end

  test ".create_or_update_by_slug!" do
    slug = "a-slug"
    original_body = "Original body"

    version1_attrs= {
      slug: slug,
      body: original_body,
    }

    created = RenderedSpecialistDocument.create_or_update_by_slug!(version1_attrs)

    assert created.is_a?(RenderedSpecialistDocument)
    assert created.persisted?

    version2_attrs = version1_attrs.merge(
      body: "Updated body",
    )

    version2 = RenderedSpecialistDocument.create_or_update_by_slug!(version2_attrs)

    assert version2.persisted?
    assert_equal "Updated body", version2.body
  end

  test ".find_by_slug" do
    created = RenderedSpecialistDocument.create!(slug: "find-by-this-slug")
    found = RenderedSpecialistDocument.find_by_slug("find-by-this-slug")

    assert_equal created, found
  end
end
