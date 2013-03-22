# encoding: UTF-8

module GovspeakSmartQuotesFixer
  def self.included(model)
    model.class_eval do
      before_validation :fix_smart_quotes_in_govspeak
    end
  end

  private

  def fix_smart_quotes_in_govspeak
    self.class::GOVSPEAK_FIELDS.each do |field|
      if self.send(field) =~ /[“”]/
        self.send(field).gsub!(/[“”]/, '"')
      end
    end
  end
end
