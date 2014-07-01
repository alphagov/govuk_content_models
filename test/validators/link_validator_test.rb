require 'test_helper'

class LinkValidatorTest < ActiveSupport::TestCase
  class Dummy
    include Mongoid::Document

    field "body", type: String
    GOVSPEAK_FIELDS = [:body]

    validates_with LinkValidator
  end

  context "links" do
    should "start with http[s]://, mailto: or /" do
      doc = Dummy.new(body: "abc [external](external.com)")
      assert doc.invalid?
      assert_includes doc.errors.keys, :body

      doc = Dummy.new(body: "abc [external](http://external.com)")
      assert doc.valid?

      doc = Dummy.new(body: "abc [internal](/internal)")
      assert doc.valid?
    end
    should "not contain hover text" do
      doc = Dummy.new(body: 'abc [foobar](http://foobar.com "hover")')
      assert doc.invalid?
      assert_includes doc.errors.keys, :body
    end
    should "not set rel=external" do
      doc = Dummy.new(body: 'abc [foobar](http://foobar.com){:rel="external"}')
      assert doc.invalid?
      assert_includes doc.errors.keys, :body
    end
    should "show multiple errors" do
      doc = Dummy.new(body: 'abc [foobar](foobar.com "bar"){:rel="external"}')
      assert doc.invalid?
      assert_equal 3, doc.errors[:body].first.length
    end
    should "only show each error once" do
      doc = Dummy.new(body: 'abc [link1](foobar.com), ghi [link2](bazquux.com)')
      assert doc.invalid?
      assert_equal 1, doc.errors[:body].first.length
    end
  end
end
