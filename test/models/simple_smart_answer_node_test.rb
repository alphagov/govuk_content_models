require "test_helper"

class SimpleSmartAnswerNodeTest < ActiveSupport::TestCase

  context "given a smart answer exists" do
    setup do
      @edition = FactoryGirl.create(:simple_smart_answer_edition)

      @atts = {
        title: "How much wood could a woodchuck chuck if a woodchuck could chuck wood?",
        slug: "how-much-wood-could-a-woodchuck-chuck-if-a-woodchuck-could-chuck-wood",
        body: "This is a serious question.",
        options: {
          "as-much-as-he-could-chuck" => "As much as he could chuck",
          "not-as-much-as-he-could-chuck" => "Not as much as he could chuck"
        },
        kind: "question"
      }
    end

    should "be able to create a valid node" do
      @node = @edition.nodes.build(@atts)

      assert @node.save!

      @edition.reload

      assert_equal "how-much-wood-could-a-woodchuck-chuck-if-a-woodchuck-could-chuck-wood", @edition.nodes.first.slug
      assert_equal "How much wood could a woodchuck chuck if a woodchuck could chuck wood?", @edition.nodes.first.title
      assert_equal "This is a serious question.", @edition.nodes.first.body
      assert_equal ["as-much-as-he-could-chuck","not-as-much-as-he-could-chuck"], @edition.nodes.first.options.keys
      assert_equal ["As much as he could chuck","Not as much as he could chuck"], @edition.nodes.first.options.values
    end

    should "not be valid without a slug" do
      @node = @edition.nodes.build( @atts.merge(slug: "") )

      assert ! @node.valid?
      assert_equal [:slug], @node.errors.keys
    end

    should "not be valid without a title" do
      @node = @edition.nodes.build( @atts.merge(title: "") )

      assert ! @node.valid?
      assert_equal [:title], @node.errors.keys
    end

    should "not be valid if options have blank labels" do
      @node = @edition.nodes.build( @atts.merge(options: { "yes" => "", "no" => "No" }) )

      assert ! @node.valid?
      assert_equal [:options], @node.errors.keys
    end

    should "not be valid without a kind" do
      @node = @edition.nodes.build(@atts.merge(:kind => nil))
      assert ! @node.valid?

      assert_equal [:kind], @node.errors.keys
    end

    should "not be valid with a kind other than 'question' or 'outcome'" do
      @node = @edition.nodes.build(@atts.merge(:kind => 'blah'))
      assert ! @node.valid?

      assert_equal [:kind], @node.errors.keys
    end

    should "permit outcomes with nil options" do
      @node = @edition.nodes.build(@atts.merge(:kind => 'outcome', options: nil))

      assert @node.valid?
      assert @node.save!
    end

    should "not be valid if an outcome has options" do
      @node = @edition.nodes.build(@atts.merge(:kind => 'outcome', options: { "foo" => "foo", "bar" => "bar" }))
      assert ! @node.valid?

      assert_equal [:options], @node.errors.keys
    end

    should "be returned in order" do
      @nodes = [
        @edition.nodes.create(@atts.merge(:title => "Third", :order => 3)),
        @edition.nodes.create(@atts.merge(:title => "First", :order => 1)),
        @edition.nodes.create(@atts.merge(:title => "Second", :order => 2)),
      ]

      assert_equal ["First","Second","Third"], @edition.nodes.all.map(&:title)
    end

    should "expose the simple smart answer edition" do
      @node = @edition.nodes.build(@atts)

      assert_equal @node.edition, @edition
    end
  end

end
