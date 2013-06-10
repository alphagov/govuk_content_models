require "test_helper"

class SimpleSmartAnswerEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  should "be created with a flow" do
    flow = { "next" => "question-one", "nodes" => { "question-one" => { "title" => "Title" } } }

    edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
    edition.body = "This is a simple smart answer."
    edition.flow = flow
    edition.save!

    edition = SimpleSmartAnswerEdition.first
    assert_equal "This is a simple smart answer.", edition.body
    assert_equal flow, edition.flow
  end

  # should "not be valid without a flow" do
  #   edition = FactoryGirl.build(:simple_smart_answer_edition, panopticon_id: @artefact.id)
  #   edition.flow = nil

  #   assert ! edition.valid?
  # end

  should "copy the body and flow when cloning an edition" do
    flow = { "next" => "question-one", "nodes" => { "question-one" => { "title" => "Title" } } }

    edition = FactoryGirl.create(:simple_smart_answer_edition,
      panopticon_id: @artefact.id,
      flow: flow,
      body: "This smart answer calls for a different kind of introduction",
      state: "published"
    )
    new_edition = edition.build_clone

    assert_equal edition.flow, new_edition.flow
    assert_equal edition.body, new_edition.body
  end

end
