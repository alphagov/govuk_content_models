require "test_helper"

class SimpleSmartAnswerConditionTest < ActiveSupport::TestCase
  context "given a smart answer node exists with a question" do
    setup do
      @option = SimpleSmartAnswerEdition::Node::Option.new(
        label: "Yes",
        slug: "question-2",
        next_node: "question-3"
      )
      @edition = FactoryGirl.create(:simple_smart_answer_edition, nodes: [
        SimpleSmartAnswerEdition::Node.new(
          slug: "question1",
          title: "Question One?",
          kind: "question",
          options: [@option]
        )
      ])
      @atts = {
        label: "Yes",
        slug: "question-1",
        next_node: "question-3"
      }
    end

    should "be able to create a valid condition" do
      @condition = @option.conditions.build(@atts)

      assert @condition.save!
      @option.reload

      assert_equal "Yes", @option.conditions.first.label
      assert_equal "question-1", @option.conditions.first.slug
      assert_equal "question-3", @option.conditions.first.next_node
    end

    should "not be valid without the slug of the conditional question" do
      @condition = @option.conditions.build(@atts.merge(slug: nil))

      refute @condition.valid?
      assert @condition.errors.keys.include?(:slug)
    end

    should "not be valid if the slug of conditional question is not valid" do
      [
        'under_score',
        'space space',
        'punct.u&ation',
      ].each do |slug|
        @condition = @option.conditions.build(@atts.merge(slug: slug))
        refute @condition.valid?
      end
    end

    should "not be valid without the value of the conditional question" do
      @condition = @option.conditions.build(@atts.merge(label: nil))

      refute @condition.valid?
      assert @condition.errors.keys.include?(:label)
    end

    should "not be valid without a value for the next_node" do
      @condition = @option.conditions.build(@atts.merge(next_node: nil))

      refute @condition.valid?
      assert @condition.errors.keys.include?(:next_node)
    end

    should "expose the option" do
      @condition = @option.conditions.create(@atts)
      @condition.reload

      assert_equal @option, @condition.option
    end
  end
end
