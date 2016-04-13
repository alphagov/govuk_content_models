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

  test "stores promotion choice and URL" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition)

    completed_transaction_edition.promotion_choice = "none"
    completed_transaction_edition.save!

    assert_equal "none", completed_transaction_edition.reload.promotion_choice

    completed_transaction_edition.promotion_choice = "organ_donor"
    completed_transaction_edition.promotion_choice_url = "https://www.organdonation.nhs.uk/registration/"
    completed_transaction_edition.save!

    assert_equal "organ_donor", completed_transaction_edition.reload.promotion_choice
    assert_equal "https://www.organdonation.nhs.uk/registration/", completed_transaction_edition.promotion_choice_url

    completed_transaction_edition.promotion_choice = "register_to_vote"
    completed_transaction_edition.promotion_choice_url = "https://www.gov.uk/register-to-vote"
    completed_transaction_edition.save!

    assert_equal "register_to_vote", completed_transaction_edition.reload.promotion_choice
    assert_equal "https://www.gov.uk/register-to-vote", completed_transaction_edition.promotion_choice_url
  end

  test "passes through legacy organ donor info" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition,
      promote_organ_donor_registration: true)

    completed_transaction_edition.organ_donor_registration_url = "https://www.organdonation.nhs.uk/registration/"
    completed_transaction_edition.save!

    assert_equal "organ_donor", completed_transaction_edition.reload.promotion_choice
    assert_equal "https://www.organdonation.nhs.uk/registration/", completed_transaction_edition.promotion_choice_url
  end
end
