class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :nodes, type: Hash
  field :body, type: String

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body, :nodes]

  validate :nodes_are_valid

  def whole_body
    body
  end

  private
  def nodes_are_valid
    return if nodes.blank?
    nodes.each do |id, node|
      if node.is_a?(Hash)
        errors.add(:nodes, "The title for #{id} cannot be blank") if node['title'].blank?
      else
        errors.add(:nodes, "#{id} is not a hash")
      end
    end
  end
end
