require "test_helper"
require "govuk_content_models/test_helpers/local_services"

class LocalTransactionEditionTest < ActiveSupport::TestCase
  include LocalServicesHelper
  def setup
    @artefact = FactoryGirl.create(:artefact)
  end

  test "should report that an authority provides a service" do
    bins_transaction = LocalTransactionEdition.new(
      lgsl_code:     "bins",
      title:         "Transaction",
      slug:          "slug",
      panopticon_id: @artefact.id
    )
    county_council = make_authority_providing("bins")
    assert bins_transaction.service_provided_by?(county_council.snac)
  end

  test "should report that an authority does not provide a service" do
    bins_transaction = LocalTransactionEdition.new(
      lgsl_code:     "bins",
      title:         "Transaction",
      slug:          "slug",
      panopticon_id: @artefact.id
    )
    county_council = make_authority_providing("housing-benefit")
    refute bins_transaction.service_provided_by?(county_council.snac)
  end

  test "should be a transaction search format" do
    bins_transaction = LocalTransactionEdition.new(
      lgsl_code:     "bins",
      title:         "Transaction",
      slug:          "slug",
      panopticon_id: @artefact.id
    )
    assert_equal "transaction", bins_transaction.search_format
  end


  test "should validate on save that a LocalService exists for that lgsl_code" do
    s = LocalService.create!(lgsl_code: "bins", providing_tier: %w{county unitary})

    lt = LocalTransactionEdition.new(lgsl_code: "nonexistent", title: "Foo", slug: "foo", panopticon_id: @artefact.id)
    lt.save
    assert !lt.valid?

    lt = LocalTransactionEdition.new(lgsl_code: s.lgsl_code, title: "Bar", slug: "bar", panopticon_id: @artefact.id)
    lt.save
    assert lt.valid?
    assert lt.persisted?
  end
end
