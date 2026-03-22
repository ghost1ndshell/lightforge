defmodule Lightforge.Characters.CharacterSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Characters.Character
  alias Lightforge.Characters.GearSnapshotItem

  schema "character_snapshots" do
    field :captured_at, :utc_datetime_usec
    field :equipped_item_level, :integer
    field :profile_json, :map, default: %{}
    field :statistics_json, :map, default: %{}
    field :achievements_json, :map, default: %{}
    field :mythic_json, :map, default: %{}
    field :media_json, :map, default: %{}

    belongs_to :character, Character
    has_many :gear_snapshot_items, GearSnapshotItem

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(character_snapshot, attrs) do
    character_snapshot
    |> cast(attrs, [
      :character_id,
      :captured_at,
      :equipped_item_level,
      :profile_json,
      :statistics_json,
      :achievements_json,
      :mythic_json,
      :media_json
    ])
    |> validate_required([
      :character_id,
      :captured_at,
      :profile_json,
      :statistics_json,
      :achievements_json,
      :mythic_json,
      :media_json
    ])
    |> validate_number(:equipped_item_level, greater_than: 0)
    |> assoc_constraint(:character)
  end
end
