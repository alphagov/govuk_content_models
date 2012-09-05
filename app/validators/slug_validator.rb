class SlugValidator < ActiveModel::EachValidator
  # implement the method called during validation
  def validate_each(record, attribute, value)
    # allow slugs to have the done/ prefix
    if value.to_s =~ /^done\/(.+)/
      value = $1
    end

    unless ActiveSupport::Inflector.parameterize(value.to_s) == value.to_s
      record.errors[attribute] << "must be usable in a URL"
    end
  end
end
