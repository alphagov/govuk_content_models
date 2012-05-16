require "part"

module Parted
  def self.included(klass)
    klass.embeds_many :parts
    klass.accepts_nested_attributes_for :parts, allow_destroy: true,
      reject_if: proc { |attrs| attrs["title"].blank? and attrs["body"].blank? }
  end

  def build_clone(edition_class=nil)
    new_edition = super

    # If the new edition is of the same type or another type that has parts,
    # copy over the parts from this edition
    if edition_class.nil? or edition_class.include? Parted
      new_edition.parts = self.parts.map {|p| p.dup }
    end

    new_edition
  end

  def order_parts
    ordered_parts = parts.sort_by { |p| p.order ? p.order : 99999 }
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end

  def whole_body
    self.parts.map {|i| %Q{\# #{i.title}\n\n#{i.body}} }.join("\n\n")
  end
end
