require "test_helper"

class CompletedTransactionEditionTest < ActiveSupport::TestCase
  test "controls whether organ donor registration promotion should be displayed on a completed transaction page" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition)
    refute completed_transaction_edition.organ_donor_promotion.display?

    completed_transaction_edition.organ_donor_promotion.display = true
    completed_transaction_edition.organ_donor_promotion.url = "https://www.organdonation.nhs.uk/registration/"
    completed_transaction_edition.save!
    assert completed_transaction_edition.reload.organ_donor_promotion.display?

    completed_transaction_edition.display_organ_donor_promotion = false
    completed_transaction_edition.save!
    refute completed_transaction_edition.reload.display_organ_donor_promotion?
  end

  test "stores organ donor registration promotion URL" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition,
      organ_donor_promotion: PresentationToggle.new(display: true, url: 'anything'))

    completed_transaction_edition.organ_donor_promotion.url = "1221"
    completed_transaction_edition.save!

    completed_transaction_edition.reload
    assert_equal "1221", completed_transaction_edition.organ_donor_promotion.url
  end

  test "returns an empty organ donor registration URL if the promotion is turned-off" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition,
      organ_donor_promotion: PresentationToggle.new(display: false, url: "https://www.organdonation.nhs.uk/registration/"))

    assert_empty completed_transaction_edition.organ_donor_promotion.url
  end

  test "invalid if organ_donor_promotion_url is not specified when promotion is on" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition,
      organ_donor_promotion: PresentationToggle.new(display: true, url: ""))

    assert completed_transaction_edition.invalid?
    assert completed_transaction_edition.organ_donor_promotion.invalid?
    assert_includes completed_transaction_edition.organ_donor_promotion.errors[:url], "can't be blank"
  end
end
