require "test_helper"
require "fact_check_address"

class FactCheckAddressTest < ActiveSupport::TestCase
  test "can tell if an address is valid" do
    service = FactCheckAddress.new
    address = service.for_edition(Edition.new)
    assert service.valid_address?(address), "Address should be valid but isn't"
  end

  test "can tell if an address is invalid" do
    service = FactCheckAddress.new
    address = "factcheck+staging-abde@alphagov.co.uk"
    refute service.valid_address?(address), "Address should be invalid but isn't"
  end
end