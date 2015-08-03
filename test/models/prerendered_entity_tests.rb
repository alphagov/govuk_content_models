# include in a test class and define a #model_class instance method

module PrerenderedEntityTests
  def test_duplicate_slug_not_allowed
    model_class.create(slug: "my-slug")
    second = model_class.create(slug: "my-slug")

    refute second.valid?
    assert_equal 1, model_class.count
  end

  def test_has_no_govspeak_fields
    refute model_class.const_defined?(:GOVSPEAK_FIELDS)
  end

  def test_create_or_update_by_slug
    slug = "a-slug"
    original_body = "Original body"

    version1_attrs= {
      slug: slug,
      body: original_body,
    }

    created = model_class.create_or_update_by_slug!(version1_attrs)

    assert created.is_a?(model_class)
    assert created.persisted?

    version2_attrs = version1_attrs.merge(
      body: "Updated body",
    )

    version2 = model_class.create_or_update_by_slug!(version2_attrs)

    assert version2.persisted?
    assert_equal "Updated body", version2.body
  end

  def test_find_by_slug
    created = model_class.create!(slug: "find-by-this-slug")
    found = model_class.find_by_slug("find-by-this-slug")

    assert_equal created, found
  end
end
