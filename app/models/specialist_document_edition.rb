class SpecialistDocumentEdition < Edition
  field :summary, type: String
  field :body, type: String
  field :opened_date, type: Date
  field :closed_date, type: Date
  field :case_type, type: String
  field :case_state, type: String
  field :market_sector, type: String
  field :outcome_type, type: String

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]

  def whole_body
    self.body
  end
end
