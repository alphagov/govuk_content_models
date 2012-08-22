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

  def check_string(record, field_name, new_value)
    dirty_html = Govspeak::Document.new(new_value).to_html
    dirty_html.strip!
    clean_html = Sanitize.clean(dirty_html, sanitize_config)
    # Trying to make whitespace consistent
    if Nokogiri::HTML.parse(dirty_html).to_s != Nokogiri::HTML.parse(clean_html).to_s
      record.errors.add(field_name, "Invalid Govspeak or JavaScript is not allowed in #{field_name}")
    end
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
