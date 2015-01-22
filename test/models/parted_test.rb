require "test_helper"
# require "edition"
# require "parted"

class PartedTest < ActiveSupport::TestCase
  test "should merge part validation errors with parent document's errors" do
    edition = FactoryGirl.create(:guide_edition)
    edition.parts.build(title: "", slug: "overview")
    edition.parts.build(title: "Prepare for your appointment", slug: "")

    refute edition.valid?
    assert_equal({title: ["can't be blank"]}, edition.errors[:parts][0][0])
    assert_equal({slug: ["can't be blank", "is invalid"]}, edition.errors[:parts][0][1])
  end

  test "should merge parts without validation errors when even one part has an error" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts)
    edition.parts.build(title: "Overview", slug: "")

    refute edition.valid?
    assert_equal({}, edition.errors[:parts][0][0])
    assert_equal({}, edition.errors[:parts][0][1])
    assert_equal({slug: ["can't be blank", "is invalid"]}, edition.errors[:parts][0][2])
  end
end
