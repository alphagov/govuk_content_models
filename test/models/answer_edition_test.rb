require 'test_helper'

class AnswerEditionTest < ActiveSupport::TestCase

  def setup
    @artefact = FactoryGirl.create(:artefact)
  end
  
  def template_answer(version_number = 1)
    artefact = FactoryGirl.create(:artefact,
        kind: "answer",
        name: "Foo bar",
        # primary_section: "test-section",
        # sections: ["test-section"],
        # department: "Test dept",
        owning_app: "publisher")

    AnswerEdition.create(state: "ready", slug: "childcare", panopticon_id: artefact.id,
      title: "Child care stuff", body: "Lots of info", version_number: version_number)
  end

  def template_published_answer(version_number = 1)
    answer = template_answer(version_number)
    answer.publish
    answer.save
    answer
  end

  context "indexable_content" do
    should "include the body of the answer" do
      assert_equal "Lots of info", template_published_answer.indexable_content
    end
  end
end