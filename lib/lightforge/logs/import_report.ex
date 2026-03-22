defmodule Lightforge.Logs.ImportReport do
  @moduledoc false

  alias Lightforge.Logs
  alias Lightforge.Repo
  alias Lightforge.WarcraftLogs.Client

  def call(code) when is_binary(code) and code != "" do
    with {:ok, report_payload} <- Client.fetch_report(code) do
      Repo.transaction(fn ->
        report = Logs.upsert_report(report_attrs(report_payload))

        fights =
          report_payload
          |> Map.get("fights", [])
          |> Enum.map(&upsert_fight(report, &1, report_payload))

        Repo.preload(report, fights: [:participants])
        |> Map.put(:fights, fights)
      end)
      |> case do
        {:ok, report} -> {:ok, report}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def call(_code), do: {:error, "A Warcraft Logs report code is required."}

  defp upsert_fight(report, fight_payload, report_payload) do
    fight =
      Logs.upsert_fight(%{
        difficulty: fight_payload["difficulty"],
        encounter_id: fight_payload["encounterID"],
        encounter_name: fight_payload["name"],
        end_time_ms: fight_payload["endTime"],
        kill: fight_payload["kill"] || false,
        raw_json: fight_payload,
        report_id: report.id,
        start_time_ms: fight_payload["startTime"],
        warcraftlogs_fight_id: fight_payload["id"]
      })

    actors_by_id =
      report_payload
      |> Map.get("masterData", %{})
      |> Map.get("actors", [])
      |> Map.new(&{Map.get(&1, "id"), &1})

    participants =
      fight_payload
      |> Map.get("friendlyPlayers", [])
      |> Enum.map(fn actor_id ->
        actor = Map.get(actors_by_id, actor_id, %{})

        Logs.upsert_participant(%{
          actor_id: actor_id,
          class_name: actor["subType"],
          fight_id: fight.id,
          name: actor["name"] || "Unknown",
          player: true,
          raw_json: actor,
          server_name: actor["server"],
          spec_name: nil
        })
      end)

    Repo.preload(fight, :participants)
    |> Map.put(:participants, participants)
  end

  defp report_attrs(report_payload) do
    %{
      code: report_payload["code"],
      end_time: unix_millis_to_datetime(report_payload["endTime"]),
      owner_name: get_in(report_payload, ["owner", "name"]),
      raw_json: report_payload,
      start_time: unix_millis_to_datetime(report_payload["startTime"]),
      title: report_payload["title"],
      visibility: report_payload["visibility"],
      zone_name: get_in(report_payload, ["zone", "name"])
    }
  end

  defp unix_millis_to_datetime(value) when is_integer(value) do
    DateTime.from_unix!(value, :millisecond)
  end

  defp unix_millis_to_datetime(_value), do: nil
end
