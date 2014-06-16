require "test_helper"
require "models/prerendered_entity_tests"

class ManualChangeHistoryTest < ActiveSupport::TestCase
  include PrerenderedEntityTests

  def model_class
    ManualChangeHistory
  end
end
