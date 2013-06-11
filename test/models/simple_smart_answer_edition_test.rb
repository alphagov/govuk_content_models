require "test_helper"

class SimpleSmartAnswerEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  should "be created with nodes" do
    nodes = { "question-one" => { "title" => "Title" } }

    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.body = "This is a simple smart answer."
    edition.nodes = nodes
    edition.save!

    edition = SimpleSmartAnswerEdition.first
    assert_equal "This is a simple smart answer.", edition.body
    assert_equal nodes, edition.nodes
  end

  should "copy the body and nodes when cloning an edition" do
    nodes = { "question-one" => { "title" => "Title" } }

    edition = FactoryGirl.create(:simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      nodes: nodes,
      body: "This smart answer calls for a different kind of introduction",
      state: "published"
    )
    new_edition = edition.build_clone

    assert_equal edition.nodes, new_edition.nodes
    assert_equal edition.body, new_edition.body
  end

end
