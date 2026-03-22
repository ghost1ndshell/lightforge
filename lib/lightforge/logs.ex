defmodule Lightforge.Logs do
  @moduledoc """
  Persistence-facing context for combat reports, fights, and participants.

  Warcraft Logs ingestion can build on these models, and downstream analysis
  providers such as WoWAnalyzer can reference the stored fights and actors.
  """

  import Ecto.Query, only: [from: 2]

  alias Lightforge.Logs.Fight
  alias Lightforge.Logs.ImportReport
  alias Lightforge.Logs.Participant
  alias Lightforge.Logs.Report
  alias Lightforge.Repo

  def list_reports do
    from(report in Report, order_by: [desc: report.inserted_at])
    |> Repo.all()
  end

  def get_report_by_code(code) when is_binary(code) do
    Repo.get_by(Report, code: code)
  end

  def create_report(attrs \\ %{}) do
    %Report{}
    |> Report.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_report(attrs) do
    %Report{}
    |> Report.changeset(attrs)
    |> Repo.insert!(
      conflict_target: [:code],
      on_conflict: {:replace, [:title, :owner_name, :visibility, :zone_name, :start_time, :end_time, :raw_json, :updated_at]},
      returning: true
    )
  end

  def list_fights(%Report{id: report_id}) do
    from(fight in Fight,
      where: fight.report_id == ^report_id,
      order_by: [asc: fight.start_time_ms],
      preload: [:participants]
    )
    |> Repo.all()
  end

  def get_fight!(id), do: Repo.get!(Fight, id)

  def create_fight(attrs \\ %{}) do
    %Fight{}
    |> Fight.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_fight(attrs) do
    %Fight{}
    |> Fight.changeset(attrs)
    |> Repo.insert!(
      conflict_target: [:report_id, :warcraftlogs_fight_id],
      on_conflict:
        {:replace,
         [:encounter_id, :encounter_name, :difficulty, :kill, :start_time_ms, :end_time_ms, :raw_json, :updated_at]},
      returning: true
    )
  end

  def list_participants(%Fight{id: fight_id}) do
    from(participant in Participant,
      where: participant.fight_id == ^fight_id,
      order_by: [asc: participant.name]
    )
    |> Repo.all()
  end

  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_participant(attrs) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert!(
      conflict_target: [:fight_id, :actor_id],
      on_conflict:
        {:replace,
         [:name, :server_name, :class_name, :spec_name, :role, :item_level, :player, :pet_owner_name, :raw_json, :updated_at]},
      returning: true
    )
  end

  def import_report(code) when is_binary(code) do
    ImportReport.call(code)
  end
end
