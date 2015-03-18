require "test_helper"

class CompletedTransactionEditionTest < ActiveSupport::TestCase
  test "controls whether organ donor registration promotion should be displayed on a completed transaction page" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition)
    refute completed_transaction_edition.promote_organ_donor_registration?

    completed_transaction_edition.promote_organ_donor_registration = true
    completed_transaction_edition.organ_donor_registration_url = "https://www.organdonation.nhs.uk/registration/"
    completed_transaction_edition.save!
    assert completed_transaction_edition.reload.promote_organ_donor_registration?

    completed_transaction_edition.promote_organ_donor_registration = false
    completed_transaction_edition.save!
    refute completed_transaction_edition.reload.promote_organ_donor_registration?
  end

  test "stores organ donor registration promotion URL" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition,
      promote_organ_donor_registration: true)

    completed_transaction_edition.organ_donor_registration_url = "https://www.organdonation.nhs.uk/registration/"
    completed_transaction_edition.save!

    assert_equal "https://www.organdonation.nhs.uk/registration/",
      completed_transaction_edition.reload.organ_donor_registration_url
  end

  test "invalid if organ_donor_registration_url is not specified when promotion is on" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition,
      promote_organ_donor_registration: true, organ_donor_registration_url: "")

    assert completed_transaction_edition.invalid?
    assert_includes completed_transaction_edition.errors[:organ_donor_registration_url], "can't be blank"
  end
end
