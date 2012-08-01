require "test_helper"
require "artefact"

def merge_attributes(original, update)
  # Merge two attribute hashes: this differs from Hash#merge in that it
  # converts symbolic keys to strings
  update.inject(original) do |old, pair|
    key, value = pair
    old.merge(key.to_s => value)
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
  end

  test "saving with no tracked changes will not create a new snapshot" do
    a = Artefact.create!(base_fields)
    a.updated_at = Time.now + 5.minutes
    a.save!
    assert_equal 1, a.actions.size
  end

end
