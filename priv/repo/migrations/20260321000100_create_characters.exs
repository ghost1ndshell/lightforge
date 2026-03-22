defmodule Lightforge.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :region, :string, null: false
      add :realm, :string, null: false
      add :realm_slug, :string, null: false
      add :name, :string, null: false
      add :blizzard_character_id, :bigint
      add :class_name, :string
      add :spec_name, :string
      add :faction_name, :string
      add :level, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:characters, [:region, :realm_slug, :name],
             name: :characters_region_realm_slug_name_index
           )
  end
end
