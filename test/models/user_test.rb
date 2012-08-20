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

  test "should create new user with oauth params" do
    auth_hash = {
      "uid" => "1234abcd",
      "info" => {
        "uid"     => "1234abcd",
        "email"   => "user@example.com",
        "name"    => "Luther Blisset"
      },
      "extra" => {
        "user" => {
          "permissions" => {
            "dummy-app" => ["signin"]
          }
        }
      }
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "user@example.com", user.email
    assert_equal "Luther Blisset", user.name
    assert_equal({ "dummy-app" => ["signin"] }, user.permissions)
  end

  test "should find and update the user with oauth params" do
    attributes = {uid: "1234abcd", name: "Old", email: "old@m.com",
        permissions: { "dummy-app" => ["everything"]}}
    User.create!(attributes, without_protection: true)
    auth_hash = {
      "uid" => "1234abcd",
      "info" => {
        "email"   => "new@m.com",
        "name"    => "New"
      },
      "extra" => {
        "user" => {
          "permissions" => {
            "dummy-app" => []
          }
        }
      }
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "new@m.com", user.email
    assert_equal "New", user.name
    assert_equal({ "dummy-app" => [] }, user.permissions)
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

  test "creating a transaction with the initial details creates a valid transaction" do
    user = User.create(:name => "bob")
    trans = user.create_edition(:transaction, title: "test", slug: "test", panopticon_id: 1234)
    assert trans.valid?
  end

  test "user can't okay a publication they've sent for review" do
    user = User.create(:name => "bob")

    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: 123)
    user.request_review(trans, {comment: "Hello"})
    assert ! user.approve_review(trans, {comment: "Hello"})
  end

  test "Edition becomes assigned to user when user is assigned an edition" do
    boss_user = User.create(:name => "Mat")
    worker_user = User.create(:name => "Grunt")

    publication = boss_user.create_edition(:answer, title: "test answer", slug: "test", panopticon_id: 123)
    boss_user.assign(publication, worker_user)
    publication.save
    publication.reload

    assert_equal(worker_user, publication.assigned_to)
  end

  test "should default to a collection called 'users'" do
    assert_equal "users", User.collection_name
  end
end
