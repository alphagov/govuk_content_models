require "test_helper"

class SimpleSmartAnswerOptionTest < ActiveSupport::TestCase

  context "given a smart answer exists with a node" do
    setup do
      @node = SimpleSmartAnswerEdition::Node.new(:slug => "question1", :title => "Question One?", :kind => "question")
      @edition = FactoryGirl.create(:simple_smart_answer_edition, :nodes => [
        @node,
        SimpleSmartAnswerEdition::Node.new(:slug => "outcome1", :title => "Outcome One", :kind => "outcome")
      ])

      @atts = {
        label: "Yes",
        next_node: "yes"
      }
    end

    should "be able to create a valid option" do
      @option = @node.options.build(@atts)

      assert @option.save!
      @node.reload

      assert_equal "Yes", @node.options.first.label
      assert_equal "yes", @node.options.first.next_node
    end

    should "not be valid without a label" do
      @option = @node.options.build(@atts.merge(label: nil))

      assert !@option.valid?
      assert @option.errors.keys.include?(:label)
    end

    should "not be valid without the next node" do
      @option = @node.options.build(@atts.merge(next_node: nil))

      assert !@option.valid?
      assert @option.errors.keys.include?(:next_node)
    end

    should "expose the node" do
      @option = @node.options.create(@atts)
      @option.reload

      assert_equal @node, @option.node
    end

    should "return in order" do
      @options = [
        @node.options.create(@atts.merge(:label => "Third", :next_node => "baz", :order => 3)),
        @node.options.create(@atts.merge(:label => "First", :next_node => "foo", :order => 1)),
        @node.options.create(@atts.merge(:label => "Second", :next_node => "bar", :order => 2)),
      ]

      assert_equal ["First","Second","Third"], @node.options.all.map(&:label)
      assert_equal ["foo","bar","baz"], @node.options.all.map(&:next_node)
    end

    context "slug" do
      should "generate a slug from the label if blank" do
        @option = @node.options.build(@atts)

        assert @option.valid?
        assert_equal "yes", @option.slug
      end

      should "keep the slug up to date if the label changes" do
        @option = @node.options.create(@atts.merge(slug: "most-likely"))
        @option.label = "Most of the times"
        assert @option.valid?
        assert_equal "most-of-the-times", @option.slug
      end

      should "not overwrite a given slug" do
        @option = @node.options.build(@atts.merge(:slug => "fooey"))

        assert @option.valid?
        assert_equal "fooey", @option.slug
      end

      should "not be valid with an invalid slug" do
        @option = @node.options.build(@atts)

        [
          'under_score',
          'space space',
          'punct.u&ation',
        ].each do |slug|
          @option.slug = slug
          refute @option.valid?
        end
      end
    end

    context "conditions" do
      should "be able to create an option without conditions" do
        @option = @node.options.build(@atts.merge(conditions_attributes: []))

        assert @option.valid?
        assert @option.save!
      end

      should "not be valid if an option has both a next node and conditions" do
        @option = @node.options.build(@atts.merge(conditions_attributes: [
          { label: "Yes", slug: "question-1", next_node: "question-3" }
        ]))

        refute @option.valid?
        assert @option.errors.keys.include?(:conditions)
      end

      should "not be valid if there are neither a next node nor conditions" do
        @option = @node.options.build(@atts.merge(next_node: nil, conditions_attributes: []))

        refute @option.valid?
        assert @option.errors.keys.include?(:next_node)
      end

      should "be able to create conditions if there is no next node on the option" do
        @option = @node.options.build(@atts.merge(next_node: nil, conditions_attributes: [
          { label: "Yes", slug: "question-1", next_node: "question-3" }
        ]))

        assert @option.valid?
      end

      should "be able to create conditions using nested attributes" do
        @option = @node.options.create!(@atts.merge(next_node: nil, conditions_attributes: [
          { label: "Yes", slug: "question-1", next_node: "question-3" },
          { label: "No", slug: "question-2", next_node: "question-4" }
        ]))

        @option.reload
        assert_equal 2, @option.conditions.count
        assert_equal ["Yes", "No"], @option.conditions.all.map(&:label)
        assert_equal ["question-1", "question-2"], @option.conditions.all.map(&:slug)
        assert_equal ["question-3", "question-4"], @option.conditions.all.map(&:next_node)
      end

      should "be able to destroy conditions using nested attributes" do
        @option = @node.options.create!(@atts.merge(next_node: nil, conditions_attributes: [
          { label: "Yes", slug: "question-1", next_node: "question-3" },
          { label: "No", slug: "question-2", next_node: "question-4" }
        ]))
        assert_equal 2, @option.conditions.count

        @option.update_attributes!(conditions_attributes: {
          "1" => { "id" => @option.conditions.first.id, "_destroy" => "1" }
        })
        @node.reload

        assert_equal 1, @option.conditions.count
        assert_equal ["No"], @option.conditions.all.map(&:label)
        assert_equal ["question-2"], @option.conditions.all.map(&:slug)
        assert_equal ["question-4"], @option.conditions.all.map(&:next_node)
      end
    end
  end
end
