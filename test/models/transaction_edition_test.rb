require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase

  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  def template_transaction
    artefact = FactoryGirl.create(:artefact)
    TransactionEdition.create(title: "One", introduction: "introduction",
      more_information: "more info", panopticon_id: @artefact.id, slug: "childcare")
  end

  context "indexable_content" do
    should "should combine the introduction and more_information" do
      assert_equal "introduction more info", template_transaction.indexable_content
    end
  end
end