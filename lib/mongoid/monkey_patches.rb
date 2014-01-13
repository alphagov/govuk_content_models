# Mongoid 2.x does not track Array field changes accurately.
# Accessing an array field will mark it dirty which becomes problematic
# for workflow callbacks, e.g. when checking if a published edition is being edited.
# See https://github.com/mongoid/mongoid/issues/2311 for details of the mongoid issue.
#
module Mongoid
  module Dirty
    def changes
      _changes = {}
      changed.each do |attr|
        change = attribute_change(attr)
        _changes[attr] = change if change
      end
      _changes
    end
  end
end
