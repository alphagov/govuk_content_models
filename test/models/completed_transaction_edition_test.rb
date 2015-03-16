require "test_helper"

class CompletedTransactionEditionTest < ActiveSupport::TestCase
  test "controls whether organ donor registration promotion should be displayed on a completed transaction page" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition)
    refute completed_transaction_edition.display_organ_donor_registration_promotion?

    completed_transaction_edition.display_organ_donor_registration_promotion = true
    completed_transaction_edition.organ_donor_registration_promotion_url = "https://www.organdonation.nhs.uk/registration/"
    completed_transaction_edition.save!
    assert completed_transaction_edition.reload.display_organ_donor_registration_promotion?

    completed_transaction_edition.display_organ_donor_registration_promotion = false
    completed_transaction_edition.save!
    refute completed_transaction_edition.reload.display_organ_donor_registration_promotion?
  end

  test "stores organ donor registration promotion URL" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition,
      display_organ_donor_registration_promotion: true)

    completed_transaction_edition.organ_donor_registration_promotion_url = "1221"
    completed_transaction_edition.save!

    assert_equal "1221", completed_transaction_edition.reload.organ_donor_registration_promotion_url
  end

  test "returns an empty organ donor registration URL if the promotion is turned-off" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition,
      display_organ_donor_registration_promotion: false, organ_donor_registration_promotion_url: "https://www.organdonation.nhs.uk/registration/")

    assert_empty completed_transaction_edition.organ_donor_registration_promotion_url
  end

  test "invalid if organ_donor_registration_promotion_url is not specified when promotion is on" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition,
      display_organ_donor_registration_promotion: true, organ_donor_registration_promotion_url: "")

    assert completed_transaction_edition.invalid?
    assert_includes completed_transaction_edition.errors[:organ_donor_registration_promotion_url], "can't be blank"
  end
end
