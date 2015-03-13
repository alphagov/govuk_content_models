require "test_helper"

class CompletedTransactionEditionTest < ActiveSupport::TestCase
  test "controls whether organ donor registration promotion should be displayed on a completed transaction page" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition)
    refute completed_transaction_edition.display_organ_donor_registration_promotion?

    completed_transaction_edition.display_organ_donor_registration_promotion = true
    completed_transaction_edition.save!
    assert completed_transaction_edition.reload.display_organ_donor_registration_promotion?

    completed_transaction_edition.display_organ_donor_registration_promotion = false
    completed_transaction_edition.save!
    refute completed_transaction_edition.reload.display_organ_donor_registration_promotion?
  end

  test "stores organ donor registration promotion code" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition,
      display_organ_donor_registration_promotion: true)

    completed_transaction_edition.organ_donor_registration_promotion_url = "1221"
    completed_transaction_edition.save!

    assert_equal "1221", completed_transaction_edition.reload.organ_donor_registration_promotion_url
  end

  test "returns an empty organ donor registration promotion code if the promotion is turned-off" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition,
      display_organ_donor_registration_promotion: false, organ_donor_registration_promotion_url: "1221")

    assert_empty completed_transaction_edition.organ_donor_registration_promotion_url
  end
end
