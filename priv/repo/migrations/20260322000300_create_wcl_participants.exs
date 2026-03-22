defmodule Lightforge.Repo.Migrations.CreateWclParticipants do
  use Ecto.Migration

  def change do
    create table(:wcl_participants) do
      add :fight_id, references(:wcl_fights, on_delete: :delete_all), null: false
      add :actor_id, :integer, null: false
      add :name, :string, null: false
      add :server_name, :string
      add :class_name, :string
      add :spec_name, :string
      add :role, :string
      add :item_level, :integer
      add :player, :boolean, null: false, default: true
      add :pet_owner_name, :string
      add :raw_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:wcl_participants, [:fight_id])
    create unique_index(:wcl_participants, [:fight_id, :actor_id])
  end
end
