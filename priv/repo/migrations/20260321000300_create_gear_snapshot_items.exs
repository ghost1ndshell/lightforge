defmodule Lightforge.Repo.Migrations.CreateGearSnapshotItems do
  use Ecto.Migration

  def change do
    create table(:gear_snapshot_items) do
      add :character_snapshot_id, references(:character_snapshots, on_delete: :delete_all),
        null: false

      add :blizzard_item_id, :bigint
      add :slot_key, :string, null: false
      add :slot_name, :string, null: false
      add :item_name, :string, null: false
      add :item_level, :integer
      add :quality, :string
      add :inventory_type, :string
      add :icon_url, :text
      add :raw_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:gear_snapshot_items, [:character_snapshot_id])
    create index(:gear_snapshot_items, [:character_snapshot_id, :slot_key])
  end
end
