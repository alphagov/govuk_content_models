require "test_helper"
require "govuk_content_models/test_helpers/local_services"
require "local_transaction_edition"
require "user"

class LocalTransactionEditionTest < ActiveSupport::TestCase
  include LocalServicesHelper

  test "should report that an authority provides a service" do
    bins_transaction = LocalTransactionEdition.new(
      lgsl_code:     "bins",
      title:         "Transaction",
      slug:          "slug",
      panopticon_id: 1
    )
    county_council = make_authority_providing("bins")
    assert bins_transaction.service_provided_by?(county_council.snac)
  end

  test "should report that an authority does not provide a service" do
    bins_transaction = LocalTransactionEdition.new(
      lgsl_code:     "bins",
      title:         "Transaction",
      slug:          "slug",
      panopticon_id: 1
    )
    county_council = make_authority_providing("housing-benefit")
    refute bins_transaction.service_provided_by?(county_council.snac)
  end

  test "should be a transaction search format" do
    bins_transaction = LocalTransactionEdition.new(
      lgsl_code:     "bins",
      title:         "Transaction",
      slug:          "slug",
      panopticon_id: 1
    )
    assert_equal "transaction", bins_transaction.search_format
  end


  test "should validate on save that a LocalService exists for that lgsl_code" do
    s = LocalService.create!(lgsl_code: "bins", providing_tier: %w{county unitary})

    lt = LocalTransactionEdition.new(lgsl_code: "nonexistent", title: "Foo", slug: "foo", panopticon_id: 1)
    lt.save
    assert !lt.valid?

    lt = LocalTransactionEdition.new(lgsl_code: s.lgsl_code, title: "Bar", slug: "bar", panopticon_id: 1)
    lt.save
    assert lt.valid?
    assert lt.persisted?
  end

  test "should create a diff between the versions when publishing a new version" do
    make_service(149, %w{county unitary})
    edition_one = LocalTransactionEdition.new(title: "Transaction", slug: "transaction", lgsl_code: "149", panopticon_id: 1)
    user = User.create name: "Thomas"

    edition_one.introduction = "Test"
    edition_one.state = :ready
    edition_one.save!

    user.publish edition_one, comment: "First edition"

    edition_two = edition_one.build_clone
    edition_two.introduction = "Testing"
    edition_two.state = :ready
    edition_two.save!

    user.publish edition_two, comment: "Second edition"

    publish_action = edition_two.actions.where(request_type: "publish").last

    assert_equal "{\"Test\" >> \"Testing\"}", publish_action.diff
  end
end
