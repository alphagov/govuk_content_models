require "test_helper"

class BusinessSupportEditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  should "have correct extra fields" do
    support = FactoryGirl.create(:business_support_edition, panopticon_id: @artefact.id)
    support.short_description = "The short description"
    support.body = "The body"
    support.eligibility = "The eligibility"
    support.evaluation = "The evaluation"
    support.additional_information = "The additional information"
    support.min_value = 1000
    support.max_value = 3000
    support.max_employees = 2000
    support.organiser = "The business support people"
    support.continuation_link = "http://www.gov.uk"
    support.will_continue_on = "The GOVUK website"
    support.contact_details = "123 The Street, Townsville, UK. 07324 123456"
    support.business_support_identifier = "123-4-5"
    support.safely.save!

    support = BusinessSupportEdition.first
    assert_equal "The short description", support.short_description
    assert_equal "The body", support.body
    assert_equal "The eligibility", support.eligibility
    assert_equal "The evaluation", support.evaluation
    assert_equal "The additional information", support.additional_information
    assert_equal 1000, support.min_value
    assert_equal 3000, support.max_value
    assert_equal 2000, support.max_employees
    assert_equal "The business support people", support.organiser
    assert_equal "http://www.gov.uk", support.continuation_link
    assert_equal "The GOVUK website", support.will_continue_on
    assert_equal "123 The Street, Townsville, UK. 07324 123456", support.contact_details
    assert_equal "123-4-5", support.business_support_identifier
  end

  should "not allow max_value to be less than min_value" do
    support = FactoryGirl.create(:business_support_edition, panopticon_id: @artefact.id)
    support.min_value = 100
    support.max_value = 50

    refute support.valid?
  end
  
  should "require a business_support_identifier" do
    support = FactoryGirl.build(:business_support_edition, :business_support_identifier => '')
    assert ! support.valid?, "expected business support edition not to be valid"
  end

  should "have a unique business support identifier" do
    support = FactoryGirl.create(:business_support_edition, panopticon_id: @artefact.id,
      business_support_identifier: "this-should-be-unique")
    another_artefact = FactoryGirl.create(:artefact)
    another_support = FactoryGirl.create(:business_support_edition, panopticon_id: another_artefact.id)
    another_support.business_support_identifier = "this-should-be-unique"
    assert !another_support.valid?, "business_support_identifier should be unique"
    another_support.business_support_identifier = "this-is-different"
    assert another_support.valid?, "business_support_identifier should be unique"
  end
  
  context "continuation_link validation" do 
  
    setup do
      @bs = FactoryGirl.create(:business_support_edition, panopticon_id: @artefact.id)
    end
    
    should "not validate the continuation link when blank" do
      @bs.continuation_link = ""
      assert @bs.valid?, "continuation link validation should not be triggered when the field is blank"
    end
    should "fail validation when the continuation link has an invalid url" do
      @bs.continuation_link = "not&a+valid_url"
      assert !@bs.valid?, "continuation link validation should fail with a invalid url"
    end
    should "pass validation with a valid continuation link url" do
      @bs.continuation_link = "http://www.hmrc.gov.uk"
      assert @bs.valid?, "continuation_link validation should pass with a valid url"
    end
  
  end
end
