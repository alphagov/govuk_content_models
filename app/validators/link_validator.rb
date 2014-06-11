class LinkValidator < ActiveModel::Validator
  def validate(record)
    record.changes.each do |field_name, (_, new_value)|
      if govspeak_fields(record).include?(field_name.to_sym)
        messages = errors(new_value)
        record.errors[field_name] << messages if messages
      end
    end
  end

  def errors(string)
    link_regex = %r{
      \[.*?\]           # link text in literal square brackets
      \(                # literal opening parenthesis
         (\S*?)           # containing URL
         (\s+"[^"]+")?    # and optional space followed by title text in quotes
      \)                # literal close paren
      (\{:rel=["']external["']\})?  # optional :rel=external in literal curly brackets.
    }x

    errors = []

    string.scan(link_regex) do |match|

      error = if match[0] !~ %r{^(?:https?://|mailto:|/)}
        'Internal links must start with a forward slash eg [link text](/link-destination). External links must start with http://, https://, or mailto: eg [external link text](https://www.google.co.uk)'
      elsif match[1]
        %q-Don't include hover text in links. Delete the text in quotation marks eg "This appears when you hover over the link."-
      elsif match[2]
        'Delete {:rel="external"} in links.'
      end

      errors << error if error
    end
    errors
  end

  protected

  def govspeak_fields(record)
    if record.class.const_defined?(:GOVSPEAK_FIELDS)
      record.class.const_get(:GOVSPEAK_FIELDS)
    else
      []
    end
  end
end

