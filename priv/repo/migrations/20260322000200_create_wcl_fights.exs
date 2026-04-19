defmodule Lightforge.Repo.Migrations.CreateWclFights do
  use Ecto.Migration

  def change do
    create table(:wcl_fights) do
      add :report_id, references(:wcl_reports, on_delete: :delete_all), null: false
      add :warcraftlogs_fight_id, :integer, null: false
      add :encounter_id, :integer
      add :encounter_name, :string
      add :difficulty, :integer
      add :kill, :boolean, null: false, default: false
      add :start_time_ms, :bigint
      add :end_time_ms, :bigint
      add :raw_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:wcl_fights, [:report_id])
    create unique_index(:wcl_fights, [:report_id, :warcraftlogs_fight_id])
    create index(:wcl_fights, [:encounter_id])
  end
end
