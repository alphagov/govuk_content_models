class SlugValidator < ActiveModel::EachValidator
  # implement the method called during validation
  def validate_each(record, attribute, value)
    if value.to_s =~ /^done\/(.+)/
      last_part = $1
    elsif value.to_s =~ /\Aforeign-travel-advice\/(.+)/ and record.kind == 'travel-advice'
      last_part = $1
    elsif value.to_s =~ /\Agovernment\/(.+)/ and record.kind == 'inside_government'
      last_part = $1
    else
      last_part = value
    end
    if record.respond_to?(:kind) and (record.kind == 'inside_government')
      unless value.to_s =~ /\Agovernment\/(.+)/
        record.errors[attribute] << "Inside Government slugs must have a government/ prefix"
      end
    end
    unless ActiveSupport::Inflector.parameterize(last_part.to_s) == last_part.to_s
      record.errors[attribute] << "must be usable in a URL"
    end
  end
end
