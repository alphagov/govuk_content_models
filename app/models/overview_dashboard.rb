class OverviewDashboard
  include Mongoid::Document

  TOTAL_KEY = "**TOTAL**"
  UNASSIGNED_KEY = "**UNASSIGNED**"

  field :dashboard_type,      type: String
  field :result_group,        type: Integer
  field :count,               type: Integer
  field :lined_up,            type: Integer
  field :draft,               type: Integer
  field :amends_needed,       type: Integer
  field :in_review,           type: Integer
  field :ready,               type: Integer
  field :fact_check_received, type: Integer
  field :fact_check,          type: Integer
  field :published,           type: Integer
  field :archived,            type: Integer

  validates_with SafeHtml
end
