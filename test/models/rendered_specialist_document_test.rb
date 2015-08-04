require "test_helper"
require "fixtures/specialist_document_fixtures"
require "models/prerendered_entity_tests"

class RenderedSpecialistDocumentTest < ActiveSupport::TestCase
  include SpecialistDocumentFixtures
  include PrerenderedEntityTests

  def model_class
    RenderedSpecialistDocument
  end
end
