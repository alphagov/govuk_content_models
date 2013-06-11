require "test_helper"

class SimpleSmartAnswerEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  should "be created with valid nodes" do
    nodes = { "question-one" => { "title" => "Title" } }

    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.body = "This is a simple smart answer."
    edition.nodes = nodes
    edition.save!

    edition = SimpleSmartAnswerEdition.first
    assert_equal "This is a simple smart answer.", edition.body
    assert_equal nodes, edition.nodes
  end

  should "preserve the order of nodes in the hash" do
    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.nodes = {
      "aardvarks" => { "title" => "Aardvarks" },
      "zebras" => { "title" => "Zebras" },
      "meerkats" => { "title" => "Meerkats" },
    }
    edition.save!
    edition.reload

    assert_equal ["aardvarks", "zebras", "meerkats"], edition.nodes.keys
  end

  should "be valid without any nodes" do
    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.body = "This is a very simple smart answer, because it has no questions."

    edition.nodes = nil
    assert edition.valid?

    edition.nodes = { }
    assert edition.valid?
  end

  should "not be valid where a node is not a hash" do
    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.nodes = { "question-one" => "string" }

    assert ! edition.valid?
    assert edition.errors.keys.include?(:nodes)

    edition.nodes = { "question-one" => [ ] }

    assert ! edition.valid?
    assert edition.errors.keys.include?(:nodes)
  end

  should "not be valid for a node without a title" do
    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.nodes = { "question-one" => { "options" => [], "title" => "" } }

    assert ! edition.valid?
    assert edition.errors.keys.include?(:nodes)

    edition.nodes = { "question-one" => { "options" => [], "title" => nil } }

    assert ! edition.valid?
    assert edition.errors.keys.include?(:nodes)
  end

  should "copy the body and nodes when cloning an edition" do
    nodes = { "question-one" => { "title" => "Title" } }

    edition = FactoryGirl.create(:simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      nodes: nodes,
      body: "This smart answer is somewhat unique and calls for a different kind of introduction",
      state: "published"
    )
    new_edition = edition.build_clone

    assert_equal edition.nodes, new_edition.nodes
    assert_equal edition.body, new_edition.body
  end

end
