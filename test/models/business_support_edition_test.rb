require "test_helper"
require "business_support_edition"

class BusinessSupportEditionTest < ActiveSupport::TestCase
  should "have correct extra fields" do
    support = FactoryGirl.create(:business_support_edition)
    support.short_description = "The short description"
    support.parts[0].body = "The description"
    support.parts[1].body = "The eligibility"
    support.parts[2].body = "The evaluation"
    support.parts[3].body = "The additional information"
    support.min_value = 1000
    support.max_value = 3000
    support.safely.save!

    support = BusinessSupportEdition.first
    assert_equal "The short description", support.short_description
    assert_equal "Description", support.parts[0].title
    assert_equal "The description", support.parts[0].body
    assert_equal "Eligibility", support.parts[1].title
    assert_equal "The eligibility", support.parts[1].body
    assert_equal "Evaluation", support.parts[2].title
    assert_equal "The evaluation", support.parts[2].body
    assert_equal "Additional information", support.parts[3].title
    assert_equal "The additional information", support.parts[3].body
    assert_equal 1000, support.min_value
    assert_equal 3000, support.max_value
  end

  should "not allow max_value to be less than min_value" do
    support = FactoryGirl.create(:business_support_edition)
    support.min_value = 100
    support.max_value = 50

    refute support.valid?
  end
end
