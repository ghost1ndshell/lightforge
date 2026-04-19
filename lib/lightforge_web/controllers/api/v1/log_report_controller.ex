defmodule LightforgeWeb.Api.V1.LogReportController do
  use LightforgeWeb, :controller

  alias Lightforge.Logs

  action_fallback LightforgeWeb.Api.V1.FallbackController

  def create(conn, %{"code" => code}) do
    with {:ok, report} <- Logs.import_report(code) do
      json(conn, %{data: serialize_report(report)})
    end
  end

  def show(conn, %{"code" => code}) do
    with report when not is_nil(report) <- Logs.get_report_by_code(code) do
      report = Lightforge.Repo.preload(report, fights: [:participants])
      json(conn, %{data: serialize_report(report)})
    else
      nil -> {:error, :not_found}
    end
  end

  defp serialize_report(report) do
    %{
      code: report.code,
      end_time: report.end_time,
      fight_count: length(report.fights || []),
      fights: Enum.map(report.fights || [], &serialize_fight/1),
      id: report.id,
      owner_name: report.owner_name,
      start_time: report.start_time,
      title: report.title,
      visibility: report.visibility,
      zone_name: report.zone_name
    }
  end

  defp serialize_fight(fight) do
    %{
      difficulty: fight.difficulty,
      encounter_id: fight.encounter_id,
      encounter_name: fight.encounter_name,
      id: fight.id,
      kill: fight.kill,
      participant_count: length(fight.participants || []),
      participants: Enum.map(fight.participants || [], &serialize_participant/1),
      start_time_ms: fight.start_time_ms,
      warcraftlogs_fight_id: fight.warcraftlogs_fight_id
    }
  end

  defp serialize_participant(participant) do
    %{
      actor_id: participant.actor_id,
      class_name: participant.class_name,
      id: participant.id,
      name: participant.name,
      player: participant.player,
      server_name: participant.server_name,
      spec_name: participant.spec_name
    }
  end
end
