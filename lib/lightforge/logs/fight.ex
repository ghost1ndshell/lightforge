defmodule Lightforge.Logs.Fight do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Analysis.AnalysisInsight
  alias Lightforge.Analysis.AnalysisRun
  alias Lightforge.Logs.Participant
  alias Lightforge.Logs.Report

  schema "wcl_fights" do
    field :warcraftlogs_fight_id, :integer
    field :encounter_id, :integer
    field :encounter_name, :string
    field :difficulty, :integer
    field :kill, :boolean, default: false
    field :start_time_ms, :integer
    field :end_time_ms, :integer
    field :raw_json, :map, default: %{}

    belongs_to :report, Report
    has_many :participants, Participant
    has_many :analysis_runs, AnalysisRun
    has_many :analysis_insights, AnalysisInsight

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(fight, attrs) do
    fight
    |> cast(attrs, [
      :report_id,
      :warcraftlogs_fight_id,
      :encounter_id,
      :encounter_name,
      :difficulty,
      :kill,
      :start_time_ms,
      :end_time_ms,
      :raw_json
    ])
    |> validate_required([:report_id, :warcraftlogs_fight_id, :raw_json])
    |> assoc_constraint(:report)
    |> unique_constraint(:warcraftlogs_fight_id, name: :wcl_fights_report_id_warcraftlogs_fight_id_index)
  end
end
