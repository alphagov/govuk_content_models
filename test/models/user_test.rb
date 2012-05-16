require "test_helper"
require "user"

class UserTest < ActiveSupport::TestCase
  test "should convert to string using name by preference" do
    user = User.new(name: "Bob", email: "user@example.com")
    assert_equal "Bob", user.to_s
  end

  test "should convert to string using email if name if missing" do
    user = User.new(email: "user@example.com")
    assert_equal "user@example.com", user.to_s
  end

  test "should convert to empty string if name and email are missing" do
    user = User.new
    assert_equal "", user.to_s
  end

  test "should find existing user by oauth hash" do
    user = User.create!("uid" => "1234abcd")
    assert_equal user, User.find_for_gds_oauth("uid" => "1234abcd")
  end

  test "should create new user with oauth params" do
    auth_hash = {
      "uid" => "1234abcd",
      "user_info" => {
        "uid"     => "1234abcd",
        "email"   => "user@example.com",
        "name"    => "Luther Blisset",
      },
      "extra" => {
        "user_hash" => {
          "version" => 2
        }
      }
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "user@example.com", user.email
    assert_equal "Luther Blisset", user.name
    assert_equal 2, user.version
  end

  test "should create insecure gravatar URL" do
    user = User.new(email: "User@example.com")
    expected = "http://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af"
    assert_equal expected, user.gravatar_url
  end

  test "should create secure gravatar URL" do
    user = User.new(email: "user@example.com")
    expected = "https://secure.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af"
    assert_equal expected, user.gravatar_url(ssl: true)
  end

  test "should add escaped s parameter if supplied" do
    user = User.new(email: "user@example.com")
    expected = "http://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af?s=foo+bar"
    assert_equal expected, user.gravatar_url(s: "foo bar")
  end
end
