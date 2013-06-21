require "test_helper"

class SimpleSmartAnswerOptionTest < ActiveSupport::TestCase

  context "given a smart answer exists with a node" do
    setup do
      @edition = FactoryGirl.create(:simple_smart_answer_edition, :nodes => [
        SimpleSmartAnswerEdition::Node.new(:slug => "question1", :title => "Question One?", :kind => "question"),
        SimpleSmartAnswerEdition::Node.new(:slug => "question1", :title => "Question One?", :kind => "outcome")
      ])
      @node = @edition.nodes.first

      @atts = {
        label: "Yes",
        next: "yes"
      }
    end

    should "be able to create a valid option" do
      @option = @node.options.build(@atts)

      assert @option.save!
      @edition.reload

      assert_equal "Yes", @edition.nodes.first.options.first.label
      assert_equal "yes", @edition.nodes.first.options.first.next
    end

    should "not be valid without a label" do
      @option = @node.options.build(@atts.merge(label: nil))

      assert !@option.valid?
      assert @option.errors.keys.include?(:label)
    end

    should "not be valid without the next node" do
      @option = @node.options.build(@atts.merge(next: nil))

      assert !@option.valid?
      assert @option.errors.keys.include?(:next)
    end

    should "expose the node" do
      @option = @node.options.create(@atts)
      @option.reload

      assert_equal @node, @option.node
    end

    should "return in order" do
      @options = [
        @node.options.create(@atts.merge(:label => "Third", :next => "baz", :order => 3)),
        @node.options.create(@atts.merge(:label => "First", :next => "foo", :order => 1)),
        @node.options.create(@atts.merge(:label => "Second", :next => "bar", :order => 2)),
      ]

      assert_equal ["First","Second","Third"], @node.options.all.map(&:label)
      assert_equal ["foo","bar","baz"], @node.options.all.map(&:next)
    end
  end
end
