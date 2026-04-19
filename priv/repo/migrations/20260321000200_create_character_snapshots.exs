defmodule Lightforge.Repo.Migrations.CreateCharacterSnapshots do
  use Ecto.Migration

  def change do
    create table(:character_snapshots) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :captured_at, :utc_datetime_usec, null: false
      add :equipped_item_level, :integer
      add :profile_json, :map, null: false, default: %{}
      add :statistics_json, :map, null: false, default: %{}
      add :achievements_json, :map, null: false, default: %{}
      add :mythic_json, :map, null: false, default: %{}
      add :media_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:character_snapshots, [:character_id])
    create index(:character_snapshots, [:character_id, :captured_at])
  end
end
