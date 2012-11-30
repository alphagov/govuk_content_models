require "test_helper"

class FactCheckAddressTest < ActiveSupport::TestCase
  test "provides a regexp that matches the addresses it produces" do
    address = FactCheckAddress.new.for_edition(Edition.new)
    assert address.match(FactCheckAddress.new.regexp)
  end
end