require "test_helper"

class TravelAdviceEditionTest < ActiveSupport::TestCase

  should "have correct fields" do
    ed = TravelAdviceEdition.new
    ed.title = "Travel advice for Aruba"
    ed.overview = "This gives travel advice for Aruba"
    ed.country_slug = 'aruba'
    ed.alert_status = [ 'avoid_all_but_essential_travel_to_parts', 'avoid_all_travel_to_parts' ]
    ed.version_number = 4
    ed.parts.build(:title => "Part One", :slug => "one")
    ed.safely.save!

    ed = TravelAdviceEdition.first
    assert_equal "Travel advice for Aruba", ed.title
    assert_equal "This gives travel advice for Aruba", ed.overview
    assert_equal 'aruba', ed.country_slug
    assert_equal [ 'avoid_all_but_essential_travel_to_parts', 'avoid_all_travel_to_parts' ], ed.alert_status
    assert_equal 4, ed.version_number
    assert_equal "Part One", ed.parts.first.title
  end

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

      should "not conflict with itself when validating uniqueness" do
        @ta.state = 'draft'
        @ta.save!
        assert @ta.valid?
      end

      should "not be modifiable when published" do
        @ta.state = 'published'
        @ta.save!
        @ta.title = 'Foo'
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:state], "must be draft to modify"
      end

      should "not be modifiable when archived" do
        @ta.state = 'archived'
        @ta.save!
        @ta.country_slug = 'foo-bar-land'
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:state], "must be draft to modify"
      end
    end

    context "on alert status" do
      should "not permit invalid values in the array" do
        @ta.alert_status = [ 'avoid_all_but_essential_travel_to_parts', 'something_else', 'blah' ]
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:alert_status], "is not in the list"
      end

      should "permit an empty array" do
        @ta.alert_status = [ ]
        assert @ta.valid?
      end
    end

    context "on version_number" do
      should "require a version_number" do
        @ta.save # version_number is automatically populated on create, so save it first.
        @ta.version_number = ''
        refute @ta.valid?
        assert_includes @ta.errors.messages[:version_number], "can't be blank"
      end

      should "require a unique version_number per slug" do
        another_edition = FactoryGirl.create(:travel_advice_edition,
                                             :country_slug => @ta.country_slug,
                                             :version_number => 3,
                                             :state => 'archived')
        @ta.version_number = 3
        refute @ta.valid?
        assert_includes @ta.errors.messages[:version_number], "is already taken"
      end

      should "allow matching version_numbers for different slugs" do
        another_edition = FactoryGirl.create(:travel_advice_edition,
                                             :country_slug => 'wibble',
                                             :version_number => 3,
                                             :state => 'archived')
        @ta.version_number = 3
        assert @ta.valid?
      end
    end
  end

  should "have a published scope" do
    e1 = FactoryGirl.create(:travel_advice_edition, :state => 'draft')
    e2 = FactoryGirl.create(:travel_advice_edition, :state => 'published')
    e3 = FactoryGirl.create(:travel_advice_edition, :state => 'archived')
    e4 = FactoryGirl.create(:travel_advice_edition, :state => 'published')

    assert_equal [e2, e4].sort, TravelAdviceEdition.published.to_a.sort
  end

  context "fields on a new edition" do
    should "be in draft state" do
      assert TravelAdviceEdition.new.draft?
    end

    context "populating version_number" do
      should "set version_number to 1 if there are no existing versions for the country" do
        ed = TravelAdviceEdition.new(:country_slug => 'foo')
        ed.valid?
        assert_equal 1, ed.version_number
      end

      should "set version_number to the next available version" do
        FactoryGirl.create(:travel_advice_edition, :country_slug => 'foo', :version_number => 1, :state => 'archived')
        FactoryGirl.create(:travel_advice_edition, :country_slug => 'foo', :version_number => 2, :state => 'archived')
        FactoryGirl.create(:travel_advice_edition, :country_slug => 'foo', :version_number => 4, :state => 'published')

        ed = TravelAdviceEdition.new(:country_slug => 'foo')
        ed.valid?
        assert_equal 5, ed.version_number
      end

      should "do nothing if version_number is already set" do
        ed = TravelAdviceEdition.new(:country_slug => 'foo', :version_number => 42)
        ed.valid?
        assert_equal 42, ed.version_number
      end

      should "do nothing if country_slug is not set" do
        ed = TravelAdviceEdition.new(:country_slug => '')
        ed.valid?
        assert_equal nil, ed.version_number
      end
    end
  end

  context "building a new version" do
    setup do
      @ed = FactoryGirl.create(:travel_advice_edition,
                               :title => "Aruba",
                               :overview => "Aruba is not near Wales",
                               :country_slug => "aruba")
      @ed.parts.build(:title => "Fooey", :slug => 'fooey', :body => "It's all about Fooey")
      @ed.parts.build(:title => "Gooey", :slug => 'gooey', :body => "It's all about Gooey")
      @ed.save!
      @ed.publish!
    end

    should "build a new instance with the same fields" do
      new_ed = @ed.build_clone
      assert new_ed.new_record?
      assert_equal @ed.title, new_ed.title
      assert_equal @ed.country_slug, new_ed.country_slug
      assert_equal @ed.overview, new_ed.overview
    end

    should "copy the edition's parts" do
      new_ed = @ed.build_clone
      assert_equal ['Fooey', 'Gooey'], new_ed.parts.map(&:title)
    end
  end

  context "publishing" do
    setup do
      @published = FactoryGirl.create(:travel_advice_edition, :country_slug => 'aruba', :state => 'published')
      @ed = FactoryGirl.create(:travel_advice_edition, :country_slug => 'aruba')
    end

    should "publish the edition and archive related editions" do
      @ed.publish!
      @published.reload
      assert @ed.published?
      assert @published.archived?
    end
  end

  context "indexable content" do
    setup do
      @edition = FactoryGirl.build(:travel_advice_edition)
    end

    should "return all part titles and bodies" do
      @edition.parts << Part.new(:title => "Summary", :body => "A summary of stuff")
      @edition.parts << Part.new(:title => "More info", :body => "Some more information")
      assert_equal "Summary A summary of stuff More info Some more information", @edition.indexable_content
    end

    should "convert govspeak to plain text" do
      @edition.parts << Part.new(:title => "Summary", :body => "A summary of stuff\n------")
      assert_equal "Summary A summary of stuff", @edition.indexable_content
    end
  end

  context "actions" do
    setup do
      @user = FactoryGirl.create(:user)
      @edition = FactoryGirl.create(:travel_advice_edition)
    end

    should "not have any actions by default" do
      assert_equal 0, @edition.actions.size
    end

    should "add a 'create' action" do
      @edition.build_action_as(@user, Action::CREATE)
      assert_equal 1, @edition.actions.size
      assert_equal Action::CREATE, @edition.actions.first.request_type
      assert_equal @user, @edition.actions.first.requester
    end

    should "add a 'new' action with a comment" do
      @edition.build_action_as(@user, Action::NEW_VERSION, "a comment for the new version")
      assert_equal 1, @edition.actions.size
      assert_equal "a comment for the new version", @edition.actions.first.comment
    end

    should "add a 'publish' action on publish" do
      @edition.publish_as(@user)
      assert_equal 1, @edition.actions.size
      assert_equal Action::PUBLISH, @edition.actions.first.request_type
    end
  end
end
