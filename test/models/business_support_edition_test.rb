# encoding: utf-8
require_relative "../test_helper"

class BusinessSupportEditionTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  should "have custom fields" do
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

    support.priority = 2
    support.business_sizes << "up-to-249"
    support.business_types << "charity"
    support.locations = ["scotland", "england"]
    support.purposes << "making-the-most-of-the-internet"
    support.sectors = ["education", "manufacturing"]
    support.stages << "start-up"
    support.support_types = ["grant", "loan"]
    support.start_date = Date.parse("1 Jan 2000")
    support.end_date = Date.parse("1 Jan 2020")

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

    assert_equal 2, support.priority
    assert_equal ["up-to-249"], support.business_sizes
    assert_equal ["charity"], support.business_types
    assert_equal ["scotland", "england"], support.locations
    assert_equal ["making-the-most-of-the-internet"], support.purposes
    assert_equal ["education", "manufacturing"], support.sectors
    assert_equal ["start-up"], support.stages
    assert_equal ["grant", "loan"], support.support_types
    assert_equal Date.parse("1 Jan 2000"), support.start_date
    assert_equal Date.parse("1 Jan 2020"), support.end_date
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

  context "business support identifier uniqueness" do
    setup do
      @support = FactoryGirl.build(:business_support_edition, panopticon_id: @artefact.id)
      @another_artefact = FactoryGirl.create(:artefact)
    end
    should "have a unique business support identifier" do
      another_support = FactoryGirl.create(:business_support_edition, panopticon_id: @another_artefact.id,
                                          :business_support_identifier => "this-should-be-unique")
      @support.business_support_identifier = "this-should-be-unique"
      assert !@support.valid?, "business_support_identifier should be unique"
      @support.business_support_identifier = "this-is-different"
      assert @support.valid?, "business_support_identifier should be unique"
    end

    should "not consider archived editions when evaluating uniqueness" do
      another_support = FactoryGirl.create(:business_support_edition, panopticon_id: @another_artefact.id,
                                           :business_support_identifier => "this-should-be-unique", :state => "archived")
      @support.business_support_identifier = "this-should-be-unique"
      assert @support.valid?, "business_support should be valid"
    end
  end

  context "numeric field validations" do
    # https://github.com/mongoid/mongoid/issues/1735 Really Mongoid‽
    [
      :min_value,
      :max_value,
      :max_employees,
    ].each do |field|
      should "require an integer #{field}" do
        @support = FactoryGirl.build(:business_support_edition)
        [
          'sadfsadf',
          '100,000',
          1.23,
        ].each do |value|
          @support.send("#{field}=", value)
          refute @support.valid?
          assert_equal 1, @support.errors[field].count
        end

        @support.send("#{field}=", "100")
        @support.save!
        s = BusinessSupportEdition.find(@support.id)
        assert_equal 100, s.send(field)

        @support.send("#{field}=", "")
        @support.save!
        s = BusinessSupportEdition.find(@support.id)
        assert_equal nil, s.send(field)
      end
    end
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

  should "clone extra fields when cloning edition" do
    support = FactoryGirl.create(:business_support_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => "published",
                                 :business_support_identifier => "1234",
                                 :short_description => "Short description of support format",
                                 :body => "Body to be cloned",
                                 :min_value => 1,
                                 :max_value => 2,
                                 :max_employees => 3,
                                 :organiser => "Organiser to be cloned",
                                 :eligibility => "Eligibility to be cloned",
                                 :evaluation => "Evaluation to be cloned",
                                 :additional_information => "Additional info to be cloned",
                                 :will_continue_on => "Continuation text to be cloned",
                                 :continuation_link => "http://www.gov.uk",
                                 :contact_details => "Contact details to be cloned")
    new_support = support.build_clone

    assert_equal support.business_support_identifier, new_support.business_support_identifier
    assert_equal support.short_description, new_support.short_description
    assert_equal support.body, new_support.body
    assert_equal support.min_value, new_support.min_value
    assert_equal support.max_value, new_support.max_value
    assert_equal support.max_employees, new_support.max_employees
    assert_equal support.organiser, new_support.organiser
    assert_equal support.eligibility, new_support.eligibility
    assert_equal support.evaluation, new_support.evaluation
    assert_equal support.additional_information, new_support.additional_information
    assert_equal support.will_continue_on, new_support.will_continue_on
    assert_equal support.continuation_link, new_support.continuation_link
    assert_equal support.contact_details, new_support.contact_details
  end
end
