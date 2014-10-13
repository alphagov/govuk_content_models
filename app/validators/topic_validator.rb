class TopicValidator < ActiveModel::Validator
  def validate(record)
    if (additional_topics = record.additional_topics)
      if additional_topics.uniq.count < additional_topics.count
        record.errors.add(:additional_topics, "can't have duplicates")
      end

      if additional_topics.include?(record.primary_topic)
        record.errors.add(:base, "You can't have the primary topic set as an additional topic")
      end
    end
  end
end
