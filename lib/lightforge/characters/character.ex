defmodule Lightforge.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightforge.Characters.CharacterSnapshot

  schema "characters" do
    field :region, :string
    field :realm, :string
    field :realm_slug, :string
    field :name, :string
    field :blizzard_character_id, :integer
    field :class_name, :string
    field :spec_name, :string
    field :faction_name, :string
    field :level, :integer

    has_many :snapshots, CharacterSnapshot

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :region,
      :realm,
      :realm_slug,
      :name,
      :blizzard_character_id,
      :class_name,
      :spec_name,
      :faction_name,
      :level
    ])
    |> validate_required([:region, :realm, :realm_slug, :name])
    |> validate_length(:region, min: 2, max: 8)
    |> validate_number(:level, greater_than_or_equal_to: 1)
    |> unique_constraint(:name, name: :characters_region_realm_slug_name_index)
  end
end
