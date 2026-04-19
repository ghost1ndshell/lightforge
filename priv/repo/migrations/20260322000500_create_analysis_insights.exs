defmodule Lightforge.Repo.Migrations.CreateAnalysisInsights do
  use Ecto.Migration

  def change do
    create table(:analysis_insights) do
      add :analysis_run_id, references(:analysis_runs, on_delete: :delete_all), null: false
      add :fight_id, references(:wcl_fights, on_delete: :delete_all), null: false
      add :participant_id, references(:wcl_participants, on_delete: :nilify_all)
      add :provider, :string, null: false
      add :source_key, :string
      add :severity, :string, null: false
      add :category, :string, null: false
      add :title, :string, null: false
      add :summary, :text
      add :recommendation, :text
      add :impact_score, :float
      add :display_order, :integer, null: false, default: 0
      add :highlighted, :boolean, null: false, default: false
      add :metadata_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:analysis_insights, [:analysis_run_id])
    create index(:analysis_insights, [:fight_id])
    create index(:analysis_insights, [:participant_id])
    create index(:analysis_insights, [:provider])
    create index(:analysis_insights, [:severity])
    create index(:analysis_insights, [:highlighted])
  end
end
