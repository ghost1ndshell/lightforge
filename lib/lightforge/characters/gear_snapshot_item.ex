defmodule Lightforge.Characters.GearSnapshotItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Characters.CharacterSnapshot

  schema "gear_snapshot_items" do
    field :blizzard_item_id, :integer
    field :slot_key, :string
    field :slot_name, :string
    field :item_name, :string
    field :item_level, :integer
    field :quality, :string
    field :inventory_type, :string
    field :icon_url, :string
    field :raw_json, :map, default: %{}

    belongs_to :character_snapshot, CharacterSnapshot

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(gear_snapshot_item, attrs) do
    gear_snapshot_item
    |> cast(attrs, [
      :character_snapshot_id,
      :blizzard_item_id,
      :slot_key,
      :slot_name,
      :item_name,
      :item_level,
      :quality,
      :inventory_type,
      :icon_url,
      :raw_json
    ])
    |> validate_required([
      :character_snapshot_id,
      :slot_key,
      :slot_name,
      :item_name,
      :raw_json
    ])
    |> validate_number(:item_level, greater_than: 0)
    |> assoc_constraint(:character_snapshot)
  end
end
