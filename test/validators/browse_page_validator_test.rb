require 'test_helper'
require 'browse_page_validator'

class BrowsePageValidatorTest < ActiveSupport::TestCase
  class Record
    include Mongoid::Document

    field :browse_pages, type: Array

    validates_with BrowsePageValidator
  end

  should "allow tagging to a variety of unique browse pages" do
    record = Record.new(
      browse_pages: [
        'business/tax',
        'housing/safety-environment'
      ]
    )

    assert record.valid?
  end

  should "be invalid if there's duplicates in the browse page list" do
    record = Record.new(
      browse_pages: [
        'housing/safety-environment',
        'housing/safety-environment'
      ]
    )

    refute record.valid?
  end
end
