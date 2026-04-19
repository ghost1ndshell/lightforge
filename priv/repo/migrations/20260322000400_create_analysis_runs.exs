defmodule Lightforge.Repo.Migrations.CreateAnalysisRuns do
  use Ecto.Migration

  def change do
    create table(:analysis_runs) do
      add :fight_id, references(:wcl_fights, on_delete: :delete_all), null: false
      add :participant_id, references(:wcl_participants, on_delete: :nilify_all)
      add :provider, :string, null: false
      add :status, :string, null: false, default: "completed"
      add :source_version, :string
      add :ruleset_version, :string
      add :started_at, :utc_datetime_usec, null: false
      add :finished_at, :utc_datetime_usec
      add :score, :float
      add :summary_json, :map, null: false, default: %{}
      add :raw_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:analysis_runs, [:fight_id])
    create index(:analysis_runs, [:participant_id])
    create index(:analysis_runs, [:provider])
    create index(:analysis_runs, [:status])
  end
end
