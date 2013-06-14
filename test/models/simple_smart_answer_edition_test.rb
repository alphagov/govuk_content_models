require "test_helper"

class SimpleSmartAnswerEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  should "be created with valid nodes" do
    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.body = "This is a simple smart answer."

    edition.nodes.build(:slug => "question1", :title => "You approach two locked doors. Which do you choose?", :kind => "question", :order => 1, :options => { "left" => "Left door", "right" => "Right door" })
    edition.nodes.build(:slug => "left", :title => "As you open the door, a lion bursts out and mauls you to death.", :order => 2, :kind => "outcome")
    edition.nodes.build(:slug => "right", :title => "As you open the door, a tiger bursts out and mauls you to death.", :order => 3, :kind => "outcome")
    edition.save!

    edition = SimpleSmartAnswerEdition.first

    assert_equal "This is a simple smart answer.", edition.body
    assert_equal 3, edition.nodes.count
    assert_equal ["question1", "left", "right"], edition.nodes.all.map(&:slug)
  end

  should "copy the body and nodes when cloning an edition" do
    edition = FactoryGirl.create(:simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      body: "This smart answer is somewhat unique and calls for a different kind of introduction",
      state: "published"
    )
    edition.nodes.build(:slug => "question1", :title => "You approach two open doors. Which do you choose?", :kind => "question", :order => 1, :options => { "left" => "Left door", "right" => "Right door" })
    edition.nodes.build(:slug => "left", :title => "As you wander through the door, it slams shut behind you, as a lion starts pacing towards you...", :order => 2, :kind => "outcome")
    edition.nodes.build(:slug => "right", :title => "As you wander through the door, it slams shut behind you, as a tiger starts pacing towards you...", :order => 3, :kind => "outcome")
    edition.save!

    new_edition = edition.build_clone

    assert_equal edition.body, new_edition.body
    assert_equal ["question", "outcome", "outcome"], new_edition.nodes.all.map(&:kind)
    assert_equal ["question1", "left", "right"], new_edition.nodes.all.map(&:slug)
  end

  should "select the first node as the starting node" do
    edition = FactoryGirl.create(:simple_smart_answer_edition)
    edition.nodes.build(:slug => "question1", :title => "Question 1", :kind => "question", :order => 1, :options => { "foo" => "Foo", "bar" => "Bar" })
    edition.nodes.build(:slug => "question2", :title => "Question 2", :kind => "question", :order => 2, :options => { "foo" => "Foo", "bar" => "Bar" })
    edition.nodes.build(:slug => "foo", :title => "Outcome 1.", :order => 3, :kind => "outcome")
    edition.nodes.build(:slug => "bar", :title => "Outcome 2", :order => 4, :kind => "outcome")

    assert_equal "question1", edition.initial_node.slug
  end

end
