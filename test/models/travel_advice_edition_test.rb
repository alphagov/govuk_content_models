require "test_helper"

class TravelAdviceEditionTest < ActiveSupport::TestCase

  context "validations" do
    setup do
      @ta = FactoryGirl.build(:travel_advice_edition)
    end

    should "require a country slug" do
      @ta.country_slug = ''
      assert ! @ta.valid?
      assert_includes @ta.errors.messages[:country_slug], "can't be blank"
    end

    context "on state" do
      should "only allow one edition in draft per slug" do
        another_edition = FactoryGirl.create(:travel_advice_edition,
                                             :country_slug => @ta.country_slug,
                                             :state => 'draft')
        @ta.state = 'draft'
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:state], "is already taken"
      end

      should "only allow one edition in published per slug" do
        another_edition = FactoryGirl.create(:travel_advice_edition,
                                             :country_slug => @ta.country_slug,
                                             :state => 'published')
        @ta.state = 'published'
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:state], "is already taken"
      end

      should "allow multiple editions in archived per slug" do
        another_edition = FactoryGirl.create(:travel_advice_edition,
                                             :country_slug => @ta.country_slug,
                                             :state => 'archived')
        @ta.state = 'archived'
        assert @ta.valid?
      end
    end
  end

  context "construction a new edition" do
    should "be in draft state" do
      assert TravelAdviceEdition.new.draft?
    end

    context "populating version_number" do

    end
  end
end
