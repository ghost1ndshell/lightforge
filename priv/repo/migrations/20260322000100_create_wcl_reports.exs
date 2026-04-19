defmodule Lightforge.Repo.Migrations.CreateWclReports do
  use Ecto.Migration

  def change do
    create table(:wcl_reports) do
      add :code, :string, null: false
      add :title, :string
      add :owner_name, :string
      add :visibility, :string
      add :zone_name, :string
      add :start_time, :utc_datetime_usec
      add :end_time, :utc_datetime_usec
      add :raw_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:wcl_reports, [:code])
  end
end
