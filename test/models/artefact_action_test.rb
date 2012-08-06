require "test_helper"
require "artefact"

def merge_attributes(original, *update_hashes)
  # Merge multiple attribute hashes: this also differs from Hash#merge in that
  # it converts symbolic keys to strings
  if update_hashes.empty?
    return original
  else
    first_update, *other_updates = update_hashes
    updated = first_update.reduce(original) do |old, pair|
      key, value = pair
      old.merge(key.to_s => value)
    end
    merge_attributes(updated, *other_updates)
  end
end

class ArtefactActionTest < ActiveSupport::TestCase

  DEFAULTS = {
    "business_proposition" => false,
    "active" => false,
    "relatedness_done" => false,
    "tag_ids" => [],
    "live" => false,
    "related_artefact_ids" => [],
  }

  def base_fields
    {
      slug: "an-artefact",
      name: "An artefact",
      kind: "answer",
      owning_app: "publisher"
    }
  end

  test "a new artefact should have a create action" do
    a = Artefact.create!(base_fields)
    a.reload

    assert_equal 1, a.actions.size
    action = a.actions.first
    assert_equal "create", action[:action_type]
    assert_equal merge_attributes(DEFAULTS, base_fields), action.snapshot
    assert action.created_at, "Action has no creation timestamp"
  end

  test "an updated artefact should have two actions" do
    a = Artefact.create!(base_fields)
    a.description = "An artefact of shining wonderment."
    a.save!
    a.reload

    assert_equal 2, a.actions.size
    assert_equal ["create", "update"], a.actions.map(&:action_type)
    create_snapshot = merge_attributes(DEFAULTS, base_fields)
    update_snapshot = create_snapshot.merge("description" => a.description)
    assert_equal create_snapshot, a.actions[0].snapshot
    assert_equal update_snapshot, a.actions[1].snapshot
    a.actions.each do |action|
      assert action.created_at, "Action has no creation timestamp"
    end
  end

  test "saving with no tracked changes will not create a new snapshot" do
    a = Artefact.create!(base_fields)
    a.updated_at = Time.now + 5.minutes
    a.save!
    assert_equal 1, a.actions.size
  end

  test "updating attributes as a user should record a user action" do
    a = Artefact.create!(base_fields)
    user = FactoryGirl.create :user
    updates = {description: "Shiny shiny description"}
    a.update_attributes_as user, updates
    a.reload

    assert_equal "Shiny shiny description", a.description
    assert_equal 2, a.actions.size
    assert_equal ["create", "update"], a.actions.map(&:action_type)
    assert_equal user, a.actions.last.user
    assert_equal(
        merge_attributes(DEFAULTS, base_fields, updates),
        a.actions.last.snapshot
    )
  end

  test "saving as a user should record a user action" do
    a = Artefact.create!(base_fields)
    user = FactoryGirl.create :user
    updates = {description: "Shiny shiny description"}
    a.description = updates[:description]
    a.save_as user
    a.reload

    assert_equal "Shiny shiny description", a.description
    assert_equal 2, a.actions.size
    assert_equal ["create", "update"], a.actions.map(&:action_type)
    assert_equal user, a.actions.last.user
    assert_equal(
        merge_attributes(DEFAULTS, base_fields, updates),
        a.actions.last.snapshot
    )
  end

  test "saving as a user with an action type" do
    a = Artefact.create!(base_fields)
    user = FactoryGirl.create :user
    updates = {description: "Shiny shiny description"}
    a.description = updates[:description]
    a.save_as user, action_type: "awesome"
    a.reload

    assert_equal user, a.actions.last.user
    assert_equal "awesome", a.actions.last.action_type
  end

end
