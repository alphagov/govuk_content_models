require "test_helper"
require "local_service"
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
    FactoryGirl.create(
      :local_interaction,
      local_authority: @county_council,
      lgsl_code:       @lgsl_code,
      url:             "http://some.county.council.gov/do-123.html"
    )
    @district_council = FactoryGirl.create(
      :local_authority,
      tier: "district",
      snac: "AA"
    )
    FactoryGirl.create(
      :local_interaction,
      local_authority: @district_council,
      lgsl_code:       @lgsl_code,
      url:             "http://some.district.council.gov/do-123.html"
    )
    @unitary_authority = FactoryGirl.create(
      :local_authority,
      tier: "unitary",
      snac: "BB00"
    )
    FactoryGirl.create(
      :local_interaction,
      local_authority: @unitary_authority,
      lgsl_code:       @lgsl_code,
      url:             "http://some.unitary.council.gov/do-123.html"
    )
  end

  test "should return county URL for county/UA service in county" do
    service = create_service_for_tiers(:county, :unitary)
    councils = [@county_council.snac, @district_council.snac]
    assert_equal "http://some.county.council.gov/do-123.html",
                 service.preferred_interaction(councils).url
  end

  test "should return UA URL for county/UA service in UA" do
    service = create_service_for_tiers(:county, :unitary)
    councils = [@unitary_authority.snac]
    assert_equal "http://some.unitary.council.gov/do-123.html",
                 service.preferred_interaction(councils).url
  end

  test "should return nil for county/UA service in district" do
    service = create_service_for_tiers(:county, :unitary)
    councils = [@district_council.snac]
    assert_nil service.preferred_interaction(councils)
  end

  test "should allow overriding returned LGIL" do
    FactoryGirl.create(:local_interaction,
      local_authority: @county_council,
      lgsl_code:       @lgsl_code,
      lgil_code:       12,
      url:             "http://some.county.council.gov/do-456.html"
    )
    service = create_service_for_tiers(:county, :unitary)
    councils = [@county_council.snac, @district_council.snac]
    assert_equal "http://some.county.council.gov/do-456.html",
                 service.preferred_interaction(councils, 12).url
  end

  test "should not list a county (in a UA) as providing a service it does not provide" do
    service = create_service_for_tiers(:county, :unitary)
    other_service = service.lgsl_code.to_i + 1
    FactoryGirl.create(
      :local_interaction,
      local_authority: @county_council,
      lgsl_code:       other_service
    )
    authority = FactoryGirl.create(
      :local_authority,
      tier: "county",
      snac: "CC00"
    )
    FactoryGirl.create(
      :local_interaction,
      local_authority: authority,
      lgsl_code:       other_service
    )

    refute_includes service.provided_by.map(&:snac), "CC00"
  end

  test "should not list a UA as providing a service it does not provide" do
    service = create_service_for_tiers(:county, :unitary)
    other_service = service.lgsl_code.to_i + 1
    FactoryGirl.create(
      :local_interaction,
      local_authority: @county_council,
      lgsl_code:       other_service
    )
    authority = FactoryGirl.create(
      :local_authority,
      tier: "unitary",
      snac: "CC01"
    )
    FactoryGirl.create(
      :local_interaction,
      local_authority: authority,
      lgsl_code:       other_service
    )

    refute_includes service.provided_by.map(&:snac), "CC01"
  end

  test "should list a county (in a UA) that provides a service" do
    service = create_service_for_tiers(:county, :unitary)
    assert_includes service.provided_by.map(&:snac), @county_council.snac
  end

  test "should list a UA that provides a service" do
    service = create_service_for_tiers(:county, :unitary)
    assert_includes service.provided_by.map(&:snac), @unitary_authority.snac
  end

  test "should return district URL for district/UA service in county/district" do
    service = create_service_for_tiers(:district, :unitary)
    councils = [@county_council.snac, @district_council.snac]
    assert_equal "http://some.district.council.gov/do-123.html",
                 service.preferred_interaction(councils).url
  end

  test "should return UA URL for district/UA service in UA" do
    service = create_service_for_tiers(:district, :unitary)
    councils = [@unitary_authority.snac]
    assert_match "http://some.unitary.council.gov/do-123.html",
                 service.preferred_interaction(councils).url
  end

  test "should return nil for district/UA service in county" do
    service = create_service_for_tiers(:district, :unitary)
    councils = [@county_council.snac]
    assert_nil service.preferred_interaction(councils)
  end

  test "should list only districts and UAs as providers" do
    service = create_service_for_tiers(:district, :unitary)
    providers = service.provided_by
    assert_equal 2, providers.length
    assert_includes providers.map(&:snac), @district_council.snac
    assert_includes providers.map(&:snac), @unitary_authority.snac
  end

  test "should return district URL for both-tier service in county/district" do
    service = create_service_for_tiers("district", "unitary", "county")
    councils = [@county_council.snac, @district_council.snac]
    url = service.preferred_interaction(councils).url
    assert_equal "http://some.district.council.gov/do-123.html", url
  end

  test "should return UA URL for both-tier service in UA" do
    service = create_service_for_tiers("district", "unitary", "county")
    councils = [@unitary_authority.snac]
    url = service.preferred_interaction(councils).url
    assert_equal "http://some.unitary.council.gov/do-123.html", url
  end

  # This shouldn't really ever happen and suggests that the data
  # is incorrect somehow, but we might as well fall back to county council
  test "should return county URL for both-tier service in county" do
    service = create_service_for_tiers("district", "unitary", "county")
    councils = [@county_council.snac]
    url = service.preferred_interaction(councils).url
    assert_equal "http://some.county.council.gov/do-123.html", url
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
