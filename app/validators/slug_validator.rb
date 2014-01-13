class SlugValidator < ActiveModel::EachValidator
  # implement the method called during validation
  def validate_each(record, attribute, value)
    if value.to_s =~ /^done\/(.+)/
      parts = [$1]
    elsif value.to_s =~ /\Aforeign-travel-advice\/(.+)/ and record.kind == 'travel-advice'
      parts = [$1]
    elsif record.respond_to?(:kind) and record.kind == 'help_page'
      if value.to_s =~ /\Ahelp\/(.+)\z/
        parts = [$1]
      else
        record.errors[attribute] << "Help page slugs must have a help/ prefix"
        return
      end
    elsif value.to_s =~ /\Agovernment\/(.+)/ and prefixed_inside_government_format_names.include?(record.kind)
      parts = $1.split('/')
    else
      parts = [value.clone]
    end

    if record.respond_to?(:kind)
      # Inside Government formats use friendly_id to disambiguate clashes, which
      # potentially results in a trailing '--1' on the last path segment.
      # Rather than overriding the fairly robust parameterize-based validation
      # below, we can just fudge the friendly_id added bit
      if inside_government_format_names.include?(record.kind) && parts.last.include?('--')
        parts.last.sub!('--', '-')
      end

      if prefixed_inside_government_format_names.include?(record.kind)
        unless value.to_s =~ /\Agovernment\/(.+)/
          record.errors[attribute] << "Inside Government slugs must have a government/ prefix"
        end
      end
    end

    parts.each do |part|
      unless ActiveSupport::Inflector.parameterize(part.to_s) == part.to_s
        record.errors[attribute] << "must be usable in a URL"
      end
    end
  end

  private
    def inside_government_format_names
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["whitehall"]
    end

    def prefixed_inside_government_format_names
      inside_government_format_names - ["detailed_guide"]
    end

end
