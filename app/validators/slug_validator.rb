class SlugValidator < ActiveModel::EachValidator
  # implement the method called during validation
  def validate_each(record, attribute, value)
    if value.to_s =~ /^done\/(.+)/
     parts = [$1]
    elsif value.to_s =~ /\Aforeign-travel-advice\/(.+)/ and record.kind == 'travel-advice'
      parts = [$1]
    elsif value.to_s =~ /\Agovernment\/(.+)/ and prefixed_inside_government_format_names.include?(record.kind)
      parts = $1.split('/')
    else
      parts = [value]
    end
    if record.respond_to?(:kind) and prefixed_inside_government_format_names.include?(record.kind)
      unless value.to_s =~ /\Agovernment\/(.+)/
        record.errors[attribute] << "Inside Government slugs must have a government/ prefix"
      end
    end
    parts.each do |part|
      unless ActiveSupport::Inflector.parameterize(part.to_s) == part.to_s
        record.errors[attribute] << "must be usable in a URL"
      end
    end
  end

  private
    def prefixed_inside_government_format_names
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["whitehall"] - ["detailed_guide"]
    end
end
