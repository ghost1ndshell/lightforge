defmodule LightforgeWeb.Api.V1.AnalysisController do
  use LightforgeWeb, :controller

  alias Lightforge.Analysis
  alias Lightforge.Logs

  action_fallback LightforgeWeb.Api.V1.FallbackController

  def create(conn, %{"fight_id" => fight_id} = params) do
    with {parsed_fight_id, ""} <- Integer.parse(fight_id),
         {:ok, run} <- Analysis.import_run(parsed_fight_id, Map.delete(params, "fight_id")) do
      json(conn, %{data: serialize_run(run)})
    else
      :error -> {:error, "Fight id is invalid."}
      {:error, reason} -> {:error, reason}
    end
  end

  def show_fight(conn, %{"fight_id" => fight_id}) do
    with {parsed_fight_id, ""} <- Integer.parse(fight_id),
         fight when not is_nil(fight) <- find_fight(parsed_fight_id),
         run when not is_nil(run) <- Analysis.get_latest_run_for_fight(fight) do
      json(conn, %{data: serialize_run(run)})
    else
      :error -> {:error, "Fight id is invalid."}
      nil -> {:error, :not_found}
    end
  end

  def show_participant(conn, %{"fight_id" => fight_id, "participant_id" => participant_id}) do
    with {parsed_fight_id, ""} <- Integer.parse(fight_id),
         {parsed_participant_id, ""} <- Integer.parse(participant_id),
         fight when not is_nil(fight) <- find_fight(parsed_fight_id),
         participant when not is_nil(participant) <-
           find_participant(fight, parsed_participant_id),
         run when not is_nil(run) <-
           Analysis.get_latest_run_for_fight_and_participant(fight, participant) do
      json(conn, %{data: serialize_run(run)})
    else
      :error -> {:error, "Fight or participant id is invalid."}
      nil -> {:error, :not_found}
    end
  end

  defp find_fight(fight_id) do
    try do
      Logs.get_fight!(fight_id)
    rescue
      Ecto.NoResultsError -> nil
    end
  end

  defp find_participant(fight, participant_id) do
    fight
    |> Logs.list_participants()
    |> Enum.find(&(&1.id == participant_id))
  end

  defp serialize_run(run) do
    insights =
      run.insights
      |> Enum.sort_by(&{not &1.highlighted, -safe_score(&1.impact_score), &1.display_order})
      |> Enum.map(&serialize_insight/1)

    %{
      fight_id: run.fight_id,
      finished_at: run.finished_at,
      id: run.id,
      insights: insights,
      participant_id: run.participant_id,
      provider: run.provider,
      ruleset_version: run.ruleset_version,
      score: run.score,
      source_version: run.source_version,
      started_at: run.started_at,
      status: run.status,
      summary_json: run.summary_json
    }
  end

  defp serialize_insight(insight) do
    %{
      category: insight.category,
      display_order: insight.display_order,
      highlighted: insight.highlighted,
      id: insight.id,
      impact_score: insight.impact_score,
      metadata_json: insight.metadata_json,
      participant_id: insight.participant_id,
      provider: insight.provider,
      recommendation: insight.recommendation,
      severity: insight.severity,
      source_key: insight.source_key,
      summary: insight.summary,
      title: insight.title
    }
  end

  defp safe_score(nil), do: -1.0
  defp safe_score(score), do: score
end
