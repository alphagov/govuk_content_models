require "edition"
require "parted"

class ProgrammeEdition < Edition
  include Parted

  @fields_to_clone = []

  DEFAULT_PARTS = [
    {title: "Overview", slug: "overview"},
    {title: "What you'll get", slug: "what-youll-get"},
    {title: "Eligibility", slug: "eligibility"},
    {title: "How to claim", slug: "how-to-claim"},
    {title: "Further information", slug: "further-information"},
  ]

  set_callback(:create, :before) do |document|
    setup_default_parts(DEFAULT_PARTS)
  end
end
