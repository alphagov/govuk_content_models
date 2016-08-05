require "test_helper"
require "govuk_content_models/test_helpers/local_services"

class LocalServiceTest < ActiveSupport::TestCase
  include LocalServicesHelper

  def create_service_for_tiers(*tiers)
    @service = LocalService.create!(
      lgsl_code:      @lgsl_code,
      providing_tier: tiers.map(&:to_s)
    )
  end

  def setup
    LocalAuthority.delete_all
    @lgsl_code = 123
    @snac_code = "AA00"
    @county_council = FactoryGirl.create(
      :local_authority,
      tier: "county",
      snac: "AA00"
    )
    @district_council = FactoryGirl.create(
      :local_authority,
      tier: "district",
      snac: "AA"
    )
    @unitary_authority = FactoryGirl.create(
      :local_authority,
      tier: "unitary",
      snac: "BB00"
    )
  end

  test "should not list a county as providing a service for districts" do
    service = create_service_for_tiers(:district, :unitary)

    refute_includes service.provided_by.map(&:snac), @county_council.snac
  end

  test "should not list a district as providing a service for counties" do
    service = create_service_for_tiers(:county, :unitary)

    refute_includes service.provided_by.map(&:snac), @district_council.snac
  end

  test "should list a county as providing a service for counties and unitaries" do
    service = create_service_for_tiers(:county, :unitary)

    assert_includes service.provided_by.map(&:snac), @county_council.snac
  end

  test "should list a district as providing a service for districts and unitaries" do
    service = create_service_for_tiers(:district, :unitary)

    assert_includes service.provided_by.map(&:snac), @district_council.snac
  end

  test "should list a UA as providing a service for counties and unitaries" do
    service = create_service_for_tiers(:county, :unitary)

    assert_includes service.provided_by.map(&:snac), @unitary_authority.snac
  end

  test "should list a UA as providing a service for districts and unitaries" do
    service = create_service_for_tiers(:county, :unitary)

    assert_includes service.provided_by.map(&:snac), @unitary_authority.snac
  end

  test "should list only districts and UAs as providers" do
    service = create_service_for_tiers(:district, :unitary)
    providers = service.provided_by
    assert_equal 2, providers.length
    assert_includes providers.map(&:snac), @district_council.snac
    assert_includes providers.map(&:snac), @unitary_authority.snac
  end

  test "should list all authorities providing a both-tier service" do
    service = create_service_for_tiers("district", "unitary", "county")
    make_authority("county", snac: "CC00", lgsl: 124)
    providers = service.provided_by
    assert_includes providers.map(&:snac), @district_council.snac
    assert_includes providers.map(&:snac), @unitary_authority.snac
    assert_includes providers.map(&:snac), @county_council.snac
  end
end
