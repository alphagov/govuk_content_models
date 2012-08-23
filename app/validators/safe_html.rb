require 'sanitize'
require 'govspeak'

class SafeHtml < ActiveModel::Validator
  def validate(record)
    record.changes.each do |field_name, (old_value, new_value)|
      check_struct(record, field_name, new_value)
    end
  end

  def check_struct(record, field_name, value)
    if value.respond_to?(:values) # e.g. Hash
      value.values.each { |entry| check_struct(record, field_name, entry) }
    elsif value.respond_to?(:each) # e.g. Array
      value.each { |entry| check_struct(record, field_name, entry) }
    elsif value.is_a?(String)
      check_string(record, field_name, value)
    end
  end

  def check_string(record, field_name, string)
    dirty_html = govspeak_to_html(string)
    clean_html = sanitize_html(dirty_html)
    unless normalise_html(dirty_html) == normalise_html(clean_html)
      record.errors.add(field_name, "cannot include invalid Govspeak or JavaScript")
    end
  end

  # Make whitespace in html tags consistent
  def normalise_html(string)
    Nokogiri::HTML.parse(string).to_s
  end

  def govspeak_to_html(string)
    Govspeak::Document.new(string).to_html
  end

  def sanitize_html(string)
    Sanitize.clean(string, sanitize_config)
  end

  def sanitize_config
    config = Sanitize::Config::RELAXED.dup

    config[:attributes][:all] << "id"
    config[:attributes][:all] << "class"
    config[:attributes]["a"]  << "rel"

    config[:elements] << "div"

    config
  end
end
