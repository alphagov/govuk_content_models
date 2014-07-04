class SlugValidator < ActiveModel::EachValidator
  # implement the method called during validation
  def validate_each(record, attribute, value)
    validators = [
      DonePageValidator,
      ForeignTravelAdvicePageValidator,
      HelpPageValidator,
      GovernmentPageValidator,
      ManualPageValidator,
      ManualChangeHistoryValidator,
      SpecialistDocumentPageValidator,
      BrowsePageValidator,
      DefaultValidator
    ].map { |klass| klass.new(record, attribute, value) }

    validators.find(&:applicable?).validate!
  end

protected
  class InstanceValidator < Struct.new(:record, :attribute, :value)
    def starts_with?(expected_prefix)
      value.to_s.start_with?(expected_prefix)
    end

    def ends_with?(expected_suffix)
      value.to_s.end_with?(expected_suffix)
    end

    def of_kind?(expected_kind)
      record.respond_to?(:kind) && [*expected_kind].include?(record.kind)
    end

    def url_after_first_slash
      value.to_s.split('/', 2)[1]
    end

    def url_after_first_slash_is_valid_slug!
      if !valid_slug?(url_after_first_slash)
        record.errors[attribute] << "must be usable in a url"
      end
    end

    def url_parts
      value.to_s.split("/")
    end

    def valid_slug?(url_part)
      # Regex taken from ActiveSupport::Inflector.parameterize
      # We don't want to use this method because it also does a number of cosmetic tidy-ups
      # which lead to false-positives (eg merging consecutive '-'s)
      ! url_part.to_s.match(/[^a-z0-9\-_]/)
    end
  end

  class DonePageValidator < InstanceValidator
    def applicable?
      starts_with?("done/")
    end

    def validate!
      url_after_first_slash_is_valid_slug!
    end
  end

  class ForeignTravelAdvicePageValidator < InstanceValidator
    def applicable?
      starts_with?("foreign-travel-advice/") && of_kind?('travel-advice')
    end

    def validate!
      url_after_first_slash_is_valid_slug!
    end
  end

  class HelpPageValidator < InstanceValidator
    def applicable?
      of_kind?('help_page')
    end

    def validate!
      record.errors[attribute] << "Help page slugs must have a help/ prefix" unless starts_with?("help/")
      url_after_first_slash_is_valid_slug!
    end
  end

  class GovernmentPageValidator < InstanceValidator
    def url_parts
      # Some inside govt slugs have a . in them (eg news articles with no english translation)
      super.map {|part| part.gsub(/\./, '') }
    end

    def applicable?
      record.respond_to?(:kind) && prefixed_whitehall_format_names.include?(record.kind)
    end

    def validate!
      record.errors[attribute] << "Inside Government slugs must have a government/ prefix" unless starts_with?('government/')
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << "must be usable in a URL"
      end
    end

  protected
    def prefixed_whitehall_format_names
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["whitehall"] - ["detailed_guide"]
    end
  end

  class ManualPageValidator < InstanceValidator
    def applicable?
      of_kind?('manual') || of_kind?('manual-section')
    end

    def validate!
      validate_number_of_parts!
      validate_guidance_prefix!
      validate_parts_as_slugs!
    end

  private
    def validate_number_of_parts!
      unless [2, 3].include?(url_parts.size)
        record.errors[attribute] << 'must contains two or three path parts'
      end
    end

    def validate_guidance_prefix!
      unless starts_with?('guidance/')
        record.errors[attribute] << 'must have a guidance/ prefix'
      end
    end

    def validate_parts_as_slugs!
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << 'must be usable in a URL'
      end
    end
  end

  class ManualChangeHistoryValidator < InstanceValidator
    def applicable?
      of_kind?('manual-change-history')
    end

    def validate!
      validate_number_of_parts!
      validate_guidance_prefix!
      validate_updates_suffix!
      validate_parts_as_slugs!
    end

  private
    def validate_number_of_parts!
      unless url_parts.size == 3
        record.errors[attribute] << 'must contain three path parts'
      end
    end

    def validate_guidance_prefix!
      unless starts_with?('guidance/')
        record.errors[attribute] << 'must have a guidance/ prefix'
      end
    end

    def validate_updates_suffix!
      unless ends_with?('/updates')
        record.errors[attribute] << 'must have a /updates suffix'
      end
    end

    def validate_parts_as_slugs!
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << 'must be usable in a URL'
      end
    end
  end

  class SpecialistDocumentPageValidator < InstanceValidator
    def applicable?
      of_kind?(acceptable_formats)
    end

    def validate!
      unless url_parts.size == 2
        record.errors[attribute] << "must be of form <finder-slug>/<specialist-document-slug>"
      end
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << "must be usable in a URL"
      end
    end

  private
    def acceptable_formats
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["specialist-publisher"] - unacceptable_formats
    end

    def unacceptable_formats
      [
        "manual",
        "manual-change-history",
        "manual-section",
      ]
    end
  end

  class BrowsePageValidator < InstanceValidator
    def applicable?
      of_kind?('specialist_sector')
    end

    def validate!
      unless [1, 2].include?(url_parts.size)
        record.errors[attribute] << "must contains one or two path parts"
      end
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << "must be usable in a URL"
      end
    end
  end

  class DefaultValidator < InstanceValidator
    def applicable?
      true
    end

    def validate!
      record.errors[attribute] << "must be usable in a url" unless valid_slug?(value)
    end
  end

end
