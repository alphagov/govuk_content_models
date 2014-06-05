require "test_helper"
require "fixtures/specialist_document_fixtures"
require "models/prerendered_entity_tests"

class RenderedSpecialistDocumentTest < ActiveSupport::TestCase
  include SpecialistDocumentFixtures
  include PrerenderedEntityTests

  def model_class
    RenderedSpecialistDocument
  end

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
end
