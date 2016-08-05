require_relative "../test_helper"

describe LocalAuthority do
  before :each do
    LocalAuthority.delete_all
  end

  it "should create an authority with correct field types" do
    # Although it may seem overboard, this test is helpful to confirm
    # the correct field types are being used on the model
    LocalAuthority.create!(
                  name: "Example",
                  snac: "AA00",
                  local_directgov_id: 1,
                  tier: "county",
                  homepage_url: 'http://example.gov/')
    authority = LocalAuthority.first
    assert_equal "Example", authority.name
    assert_equal "AA00", authority.snac
    assert_equal 1, authority.local_directgov_id
    assert_equal "county", authority.tier
    assert_equal "http://example.gov/", authority.homepage_url
  end
end
