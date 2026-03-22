defmodule Lightforge.Logs.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Analysis.AnalysisInsight
  alias Lightforge.Analysis.AnalysisRun
  alias Lightforge.Logs.Fight

  schema "wcl_participants" do
    field :actor_id, :integer
    field :name, :string
    field :server_name, :string
    field :class_name, :string
    field :spec_name, :string
    field :role, :string
    field :item_level, :integer
    field :player, :boolean, default: true
    field :pet_owner_name, :string
    field :raw_json, :map, default: %{}

    belongs_to :fight, Fight
    has_many :analysis_runs, AnalysisRun
    has_many :analysis_insights, AnalysisInsight

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [
      :fight_id,
      :actor_id,
      :name,
      :server_name,
      :class_name,
      :spec_name,
      :role,
      :item_level,
      :player,
      :pet_owner_name,
      :raw_json
    ])
    |> validate_required([:fight_id, :actor_id, :name, :raw_json])
    |> assoc_constraint(:fight)
    |> unique_constraint(:actor_id, name: :wcl_participants_fight_id_actor_id_index)
  end
end
