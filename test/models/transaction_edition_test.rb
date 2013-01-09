require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase

  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  context "indexable_content" do
    should "include the introduction without markup" do
      transaction = FactoryGirl.create(:transaction_edition, introduction: "## introduction", more_information: "", panopticon_id: @artefact.id)
      assert_equal "introduction", transaction.indexable_content
    end

    should "include the more_information without markup" do
      transaction = FactoryGirl.create(:transaction_edition, more_information: "## more info", introduction: "", panopticon_id: @artefact.id)
      assert_equal "more info", transaction.indexable_content
    end
  end
end