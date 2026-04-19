defmodule Lightforge.Analysis.AnalysisInsight do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Analysis.AnalysisRun
  alias Lightforge.Logs.Fight
  alias Lightforge.Logs.Participant

  schema "analysis_insights" do
    field :provider, :string
    field :source_key, :string
    field :severity, :string
    field :category, :string
    field :title, :string
    field :summary, :string
    field :recommendation, :string
    field :impact_score, :float
    field :display_order, :integer, default: 0
    field :highlighted, :boolean, default: false
    field :metadata_json, :map, default: %{}

    belongs_to :analysis_run, AnalysisRun
    belongs_to :fight, Fight
    belongs_to :participant, Participant

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(insight, attrs) do
    insight
    |> cast(attrs, [
      :analysis_run_id,
      :fight_id,
      :participant_id,
      :provider,
      :source_key,
      :severity,
      :category,
      :title,
      :summary,
      :recommendation,
      :impact_score,
      :display_order,
      :highlighted,
      :metadata_json
    ])
    |> validate_required([
      :analysis_run_id,
      :fight_id,
      :provider,
      :severity,
      :category,
      :title,
      :metadata_json
    ])
    |> assoc_constraint(:analysis_run)
    |> assoc_constraint(:fight)
    |> assoc_constraint(:participant)
  end
end
