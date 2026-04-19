defmodule Lightforge.Analysis.AnalysisRun do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Analysis.AnalysisInsight
  alias Lightforge.Logs.Fight
  alias Lightforge.Logs.Participant

  schema "analysis_runs" do
    field :provider, :string
    field :status, :string, default: "completed"
    field :source_version, :string
    field :ruleset_version, :string
    field :started_at, :utc_datetime_usec
    field :finished_at, :utc_datetime_usec
    field :score, :float
    field :summary_json, :map, default: %{}
    field :raw_json, :map, default: %{}

    belongs_to :fight, Fight
    belongs_to :participant, Participant
    has_many :insights, AnalysisInsight

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :fight_id,
      :participant_id,
      :provider,
      :status,
      :source_version,
      :ruleset_version,
      :started_at,
      :finished_at,
      :score,
      :summary_json,
      :raw_json
    ])
    |> validate_required([:fight_id, :provider, :status, :started_at, :summary_json, :raw_json])
    |> assoc_constraint(:fight)
    |> assoc_constraint(:participant)
  end
end
