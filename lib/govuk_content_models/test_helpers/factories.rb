require "factory_girl"
require "answer_edition"
require "artefact"
require "tag"
require "user"

FactoryGirl.define do
  factory :user do
    sequence(:uid) { |n| "uid-#{n}"}
    sequence(:name) { |n| "Joe Bloggs #{n}" }
    sequence(:email) { |n| "joe#{n}@bloggs.com" }
    if defined?(GDS::SSO::Config)
      # Grant permission to signin to the app using the gem
      permissions { ["signin"] }
    end
  end

  factory :tag do
    sequence(:tag_id) { |n| "crime-and-justice/the-police-#{n}" }
    sequence(:title) { |n| "The title #{n}" }
    tag_type "section"
  end

  factory :artefact do
    sequence(:name) { |n| "Artefact #{n}" }
    sequence(:slug) { |n| "slug-#{n}" }
    kind            Artefact::FORMATS.first
    owning_app      'publisher'
  end

  factory :non_publisher_artefact, parent: :artefact do
    kind            'smart-answer'
    owning_app      'smart-answers'
  end

  factory :edition, class: AnswerEdition do
    panopticon_id {
        a = create(:artefact)
        a.id
      }

    sequence(:slug) { |n| "slug-#{n}" }
    sequence(:title) { |n| "A key answer to your question #{n}" }

    section "test:subsection test"

    association :assigned_to, factory: :user
  end
  factory :answer_edition, parent: :edition do
  end

  factory :help_page_edition, :parent => :edition, :class => 'HelpPageEdition' do
  end

  factory :campaign_edition, :parent => :edition, :class => 'CampaignEdition' do
  end

  factory :completed_transaction_edition, :parent => :edition, :class => 'CompletedTransactionEdition' do
  end

  factory :video_edition, parent: :edition, :class => 'VideoEdition' do
  end

  factory :business_support_edition, :parent => :edition, :class => "BusinessSupportEdition" do
    sequence(:business_support_identifier) {|n| "identifier-#{n}" }
  end

  factory :guide_edition do |ge|
    panopticon_id {
        a = create(:artefact)
        a.id
      }
    ge.sequence(:title)  { |n| "Test guide #{n}" }
    ge.sequence(:slug) { |ns| "slug-#{ns}"}
    section { "test:subsection test" }
  end

  factory :programme_edition do |edition|
    panopticon_id {
        a = create(:artefact)
        a.id
      }
    edition.sequence(:title) { |n| "Test programme #{n}" }
    edition.sequence(:slug) { |ns| "slug-#{ns}"}
    section { "test:subsection test" }
  end

  factory :programme_edition_with_multiple_parts, parent: :programme_edition do
    title "a title"
    after :create do |getp|
      getp.parts.build(title: "PART !", body: "This is some programme version text.",
                       slug: "part-one")
      getp.parts.build(title: "PART !!",
                       body: "This is some more programme version text.",
                       slug: "part-two")
    end
  end

  factory :guide_edition_with_two_parts, parent: :guide_edition do
    title "a title"
    after :create do |getp|
      getp.parts.build(title: "PART !", body: "This is some version text.",
                       slug: "part-one")
      getp.parts.build(title: "PART !!",
                       body: "This is some more version text.",
                       slug: "part-two")
    end
  end

  factory :guide_edition_with_two_govspeak_parts, parent: :guide_edition do
    title "A title for govspeak parts"
    after :create do |getp|
      getp.parts.build(title: "Some Part Title!",
                       body: "This is some **version** text.", slug: "part-one")
      getp.parts.build(title: "Another Part Title",
                       body: "This is [link](http://example.net/) text.",
                       slug: "part-two")
    end
  end

  factory :local_transaction_edition do |lte|
    panopticon_id {
        a = create(:artefact)
        a.id
      }
    title  { "Test title" }
    version_number 1
    lte.sequence(:slug) { |ns| "slug-#{ns}"}
    lte.sequence(:lgsl_code) { |nlgsl| nlgsl }
    introduction { "Test introduction" }
    more_information { "This is more information" }
  end

  factory :transaction_edition do |te|
    panopticon_id {
        a = create(:artefact)
        a.id
      }
    title  { "Test title" }
    version_number 1
    introduction { "Test introduction" }
    more_information { "This is more information" }
    link "http://continue.com"
    will_continue_on "To be continued..."
    alternate_methods "Method A or Method B"
  end

  factory :licence_edition, :parent => :edition, :class => "LicenceEdition" do
    licence_identifier "AB1234"
  end

  factory :local_service do |ls|
    ls.sequence(:lgsl_code)
    providing_tier { %w{district unitary county} }
  end

  factory :local_authority do
    name "Some Council"
    sequence(:snac) {|n| "%02dAA" % n }
    sequence(:local_directgov_id)
    tier "county"
  end

  factory :local_authority_with_contact, parent: :local_authority do
    contact_address ["line one", "line two", "line three"]
    contact_url "http://www.magic.com/contact"
    contact_phone "0206778654"
    contact_email "contact@local.authority.gov.uk"
  end

  factory :local_interaction do
    association :local_authority
    url "http://some.council.gov/do.html"
    sequence(:lgsl_code) {|n| 120 + n }
    lgil_code 0
  end

  factory :expectation do
    sequence(:text) {|n| "You will need #{n} of these."}
  end

  factory :place_edition do
    title "Far far away"
    introduction "Test introduction"
    more_information "More information"
    place_type "Location location location"
  end

  factory :curated_list do
    sequence(:slug) { |n| "slug-#{n}" }
  end

  factory :travel_advice_edition do
    sequence(:country_slug) {|n| "test-country-#{n}" }
    sequence(:title) {|n| "Test Country #{n}" }
    change_description "Stuff changed"
  end

  # These factories only work when used with FactoryGirl.create
  factory :draft_travel_advice_edition, :parent => :travel_advice_edition do
  end
  factory :published_travel_advice_edition, :parent => :travel_advice_edition do
    after :create do |tae|
      tae.published_at ||= Time.zone.now.utc
      tae.state = 'published'
      tae.save!
    end
  end
  factory :archived_travel_advice_edition, :parent => :travel_advice_edition do
    after :create do |tae|
      tae.state = 'archived'
      tae.save!
    end
  end

  factory :simple_smart_answer_edition do
    panopticon_id {
      a = create(:artefact)
      a.id
    }
    title "Simple smart answer"
    body "Introduction to the smart answer"
  end
end
