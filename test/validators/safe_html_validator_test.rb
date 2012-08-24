require 'test_helper'

class SafeHtmlTest < ActiveSupport::TestCase
  class ::Dummy
    include Mongoid::Document

    field "declared", type: String

    validates_with SafeHtml

    embeds_one :dummy_embedded_single
  end

  class ::DummyEmbeddedSingle
    include Mongoid::Document

    validates_with SafeHtml

    embedded_in :dummy
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
  end

  context "validating a field" do
    should "allow plain text" do
      dummy = Dummy.new(declared: "foo bar")
      assert dummy.valid?
    end

    should "allow Govspeak Markdown" do
      values = [
        "## is H2",
        "*bold text*",
        "* bullet",
        "- alternative bullet",
        "+ another bullet",
        "1. Numbered list",
        "s2. Step",
        """
        Table | Header
        - | -
        Build | cells
        """,
        "This is [an example](/an-inline-link \"Title\") inline link.",
        "<http://example.com/>",
        "<address@example.com>",
        "This is [an example](http://example.com/ \"Title\"){:rel=\"external\"} inline link to an external resource.",
        "^Your text here^ - creates a callout with an info (i) icon.",
        "%Your text here% - creates a callout with a warning or alert (!) icon",
        "@Your text here@ - highlights the enclosed text in yellow",
        "$CSome contact information here$C - contact information",
        "$A Hercules House Hercules Road London SE1 7DU $A",
        "$D [An example form download link](http://example.com/ \"Example form\") Something about this form download $D",
        "$EAn example for the citizen$E - examples boxout",
        "$!...$! - answer summary",
        "{::highlight-answer}...{:/highlight-answer} - creates a large pink highlight box with optional preamble text and giant text denoted with **.",
        "{::highlight-answer}",
        "The VAT rate is *20%*",
        "{:/highlight-answer}",
        "---",
        "*[GDS]: Government Digital Service",
        """
        $P

        $I
        $A
        Hercules House
        Hercules Road
        London SE1 7DU
        $A

        $AI
        There is access to the building from the street via a ramp.
        $AI
        $I
        $P
        """,
        ":england:content goes here:england:",
        ":scotland:content goes here:scotland:"
      ]
      values.each do |value|
        dummy = Dummy.new(declared: value)
        assert dummy.valid?, "This failed validation: #{value}"
      end
    end

    should "disallow a script tag" do
      dummy = Dummy.new(declared: "<script>alert('XSS')</script>")
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :declared
    end

    should "disallow a javascript protocol in an attribute" do
      dummy = Dummy.new(declared: %q{<a href="javascript:alert(document.location);" title="Title">an example</a>})
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :declared
    end

    should "disallow a javascript protocol in a Markdown link" do
      dummy = Dummy.new(declared: %q{This is [an example](javascript:alert(""); "Title") inline link.})
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :declared
    end

    should "disallow on* attributes" do
      dummy = Dummy.new(declared: %q{<a href="/" onclick="alert('xss');">Link</a>})
      assert dummy.invalid?
      assert_includes dummy.errors.keys, :declared
    end

    should "allow non-JS HTML content" do
      dummy = Dummy.new(declared: "<a href='foo'>")
      assert dummy.valid?
    end

    should "allow things that will end up as HTML entities" do
      dummy = Dummy.new(declared: "Fortnum & Mason")
      assert dummy.valid?
    end

    should "all models should use this validator" do
      classes = ObjectSpace.each_object(::Module).select do |klass|
        klass < Mongoid::Document
      end

      classes.each do |klass|
        assert_includes klass.validators.map(&:class), SafeHtml, "#{klass} must be validated with SafeHtml"
      end
    end
  end
end