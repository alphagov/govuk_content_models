require 'test_helper'
require 'topic_validator'

class TopicValidatorTest < ActiveSupport::TestCase
  class Record
    include Mongoid::Document

    field :primary_topic, type: String
    field :additional_topics, type: Array

    validates_with TopicValidator
  end

  should "allow tagging to a variety of unique topics" do
    record = Record.new(
      primary_topic: 'oil-and-gas/exploration',
      additional_topics: [
        'oil-and-gas/fields-and-wells',
        'oil-and-gas/licensing'
      ]
    )

    assert record.valid?
  end

  should "be invalid if there's duplicates in the additional topic list" do
    record = Record.new(
      additional_topics: [
        'oil-and-gas/fields-and-wells',
        'oil-and-gas/fields-and-wells'
      ]
    )

    refute record.valid?
  end

  should "be invalid if the primary topic is in the additional topic list" do
    record = Record.new(
      primary_topic: 'oil-and-gas/fields-and-wells',
      additional_topics: [
        'oil-and-gas/fields-and-wells',
        'oil-and-gas/licensing'
      ]
    )

    refute record.valid?
  end
end
