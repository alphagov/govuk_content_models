require 'test_helper'

class SafeHtmlTest < ActiveSupport::TestCase
  class Dummy
    include Mongoid::Document

    field "declared", type: String
    field "i_am_govspeak", type: String

    GOVSPEAK_FIELDS = [:i_am_govspeak]

    validates_with SafeHtml

    embeds_one :dummy_embedded_single, class_name: 'SafeHtmlTest::DummyEmbeddedSingle'
  end

  class DummyEmbeddedSingle
    include Mongoid::Document

    GOVSPEAK_FIELDS = []

    validates_with SafeHtml

    embedded_in :dummy, class_name: 'SafeHtmlTest::Dummy'
  end

  context "we don't quite trust mongoid (2)" do
    should "embedded documents should be validated automatically" do
      embedded = DummyEmbeddedSingle.new(dirty: "<script>")
      dummy = Dummy.new(dummy_embedded_single: embedded)
      # Can't invoke embedded.valid? because that would run the validations
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :dummy_embedded_single
    end
  end

  context "what to validate" do
    should "test declared fields" do
      dummy = Dummy.new(declared: "<script>alert('XSS')</script>")
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :declared
    end

    should "test undeclared fields" do
      dummy = Dummy.new(undeclared: "<script>")
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :undeclared
    end

    should "allow clean content in nested fields" do
      dummy = Dummy.new(undeclared: { "clean" => ["plain text"] })
      assert dummy.valid?
    end

    should "disallow dirty content in nested fields" do
      dummy = Dummy.new(undeclared: { "dirty" => ["<script>"] })
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :undeclared
    end

    should "allow plain text" do
      dummy = Dummy.new(declared: "foo bar")
      assert dummy.valid?
    end

    should "check only specified fields as Govspeak" do
      nasty_govspeak = %q{[Numberwang](script:nasty(); "Wangernum")}
      assert ! Govspeak::Document.new(nasty_govspeak).valid?, "expected this to be identified as bad"
      dummy = Dummy.new(i_am_govspeak: nasty_govspeak)
      assert dummy.invalid?
    end

    should "all models should use this validator" do
      models_dir = File.expand_path("../../app/models/*", File.dirname(__FILE__))

      classes = Dir[models_dir].map do |file|
        klass = File.basename(file, ".rb").camelize.constantize
        klass.included_modules.include?(Mongoid::Document) ? klass : nil
      end.compact

      classes.each do |klass|
        assert_includes klass.validators.map(&:class), SafeHtml, "#{klass} must be validated with SafeHtml"
      end
    end
  end
end
