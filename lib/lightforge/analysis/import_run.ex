defmodule Lightforge.Analysis.ImportRun do
  @moduledoc false

  alias Ecto.Multi
  alias Lightforge.Analysis.AnalysisInsight
  alias Lightforge.Analysis.AnalysisRun
  alias Lightforge.Logs.Fight
  alias Lightforge.Logs.Participant
  alias Lightforge.Repo

  def call(fight_id, attrs) when is_integer(fight_id) and is_map(attrs) do
    with %Fight{} = fight <- Repo.get(Fight, fight_id),
         normalized_attrs <- stringify_keys(attrs),
         {:ok, participant_id} <-
           validate_participant(fight_id, Map.get(normalized_attrs, "participant_id")) do
      run_attrs =
        normalized_attrs
        |> Map.put("fight_id", fight.id)
        |> Map.put("participant_id", participant_id)
        |> Map.put_new("started_at", DateTime.utc_now())
        |> Map.put_new("status", "completed")
        |> Map.put_new("summary_json", %{})
        |> Map.put_new("raw_json", %{})

      insights = Map.get(normalized_attrs, "insights", [])

      Multi.new()
      |> Multi.insert(:run, AnalysisRun.changeset(%AnalysisRun{}, run_attrs))
      |> insert_insights(insights, fight.id, participant_id)
      |> Repo.transaction()
      |> case do
        {:ok, %{run: run}} ->
          {:ok, Repo.preload(run, [:participant, :insights])}

        {:error, _step, changeset, _changes_so_far} ->
          {:error, changeset}
      end
    else
      nil -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_fight_id, _attrs), do: {:error, "Analysis import payload is invalid."}

  defp validate_participant(_fight_id, nil), do: {:ok, nil}

  defp validate_participant(fight_id, participant_id) when is_integer(participant_id) do
    case Repo.get_by(Participant, id: participant_id, fight_id: fight_id) do
      %Participant{} -> {:ok, participant_id}
      nil -> {:error, "Participant does not belong to the requested fight."}
    end
  end

  defp validate_participant(_fight_id, _participant_id), do: {:error, "Participant is invalid."}

  defp insert_insights(multi, insights, fight_id, participant_id) when is_list(insights) do
    Enum.reduce(Enum.with_index(insights), multi, fn {insight_attrs, index}, acc ->
      Multi.insert(acc, {:insight, index}, fn %{run: run} ->
        attrs =
          insight_attrs
          |> stringify_keys()
          |> Map.put("analysis_run_id", run.id)
          |> Map.put_new("fight_id", fight_id)
          |> Map.put_new("participant_id", participant_id)
          |> Map.put_new("provider", run.provider)
          |> Map.put_new("metadata_json", %{})
          |> Map.put_new("display_order", index)

        AnalysisInsight.changeset(%AnalysisInsight{}, attrs)
      end)
    end)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end
end
