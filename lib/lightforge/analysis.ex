defmodule Lightforge.Analysis do
  @moduledoc """
  Persistence-facing context for encounter analysis runs and actionable insights.

  The intention is to store provider-specific output, such as future
  WoWAnalyzer-derived recommendations, in a form that is already filtered,
  ranked, and easy for the frontend to present.
  """

  import Ecto.Query, only: [from: 2]

  alias Lightforge.Analysis.AnalysisInsight
  alias Lightforge.Analysis.AnalysisRun
  alias Lightforge.Analysis.ImportRun
  alias Lightforge.Characters.Character
  alias Lightforge.Logs.Fight
  alias Lightforge.Logs.Participant
  alias Lightforge.Repo

  def list_runs_for_fight(%Fight{id: fight_id}) do
    from(run in AnalysisRun,
      where: run.fight_id == ^fight_id,
      order_by: [desc: run.inserted_at],
      preload: [:participant, :insights]
    )
    |> Repo.all()
  end

  def create_run(attrs \\ %{}) do
    %AnalysisRun{}
    |> AnalysisRun.changeset(attrs)
    |> Repo.insert()
  end

  def get_latest_run_for_fight(%Fight{id: fight_id}) do
    from(run in AnalysisRun,
      where: run.fight_id == ^fight_id and is_nil(run.participant_id),
      order_by: [desc: run.inserted_at],
      limit: 1,
      preload: [:participant, :insights]
    )
    |> Repo.one()
  end

  def get_latest_run_for_fight_and_participant(%Fight{id: fight_id}, %Participant{
        id: participant_id
      }) do
    from(run in AnalysisRun,
      where: run.fight_id == ^fight_id and run.participant_id == ^participant_id,
      order_by: [desc: run.inserted_at],
      limit: 1,
      preload: [:participant, :insights]
    )
    |> Repo.one()
  end

  def get_latest_run_for_character(%Character{} = character) do
    normalized_name = normalize_identity_segment(character.name)
    normalized_realm = normalize_identity_segment(character.realm)
    normalized_realm_slug = normalize_identity_segment(character.realm_slug)
    normalized_class = normalize_identity_segment(character.class_name)
    normalized_spec = normalize_identity_segment(character.spec_name)

    from(run in AnalysisRun,
      join: participant in assoc(run, :participant),
      where:
        not is_nil(run.participant_id) and
          fragment("lower(?)", participant.name) == ^normalized_name,
      order_by: [desc: run.inserted_at],
      preload: [participant: participant, fight: [:report], insights: ^insights_query()]
    )
    |> Repo.all()
    |> Enum.find(fn run ->
      participant_matches_character?(
        run.participant,
        normalized_realm,
        normalized_realm_slug,
        normalized_class,
        normalized_spec
      )
    end)
  end

  def list_insights_for_run(%AnalysisRun{id: run_id}) do
    from(insight in AnalysisInsight,
      where: insight.analysis_run_id == ^run_id,
      order_by: [
        desc: insight.highlighted,
        desc: insight.impact_score,
        asc: insight.display_order
      ]
    )
    |> Repo.all()
  end

  def list_insights_for_fight(%Fight{id: fight_id}) do
    from(insight in AnalysisInsight,
      where: insight.fight_id == ^fight_id,
      order_by: [
        desc: insight.highlighted,
        desc: insight.impact_score,
        asc: insight.display_order
      ]
    )
    |> Repo.all()
  end

  def list_insights_for_participant(%Participant{id: participant_id}) do
    from(insight in AnalysisInsight,
      where: insight.participant_id == ^participant_id,
      order_by: [
        desc: insight.highlighted,
        desc: insight.impact_score,
        asc: insight.display_order
      ]
    )
    |> Repo.all()
  end

  def create_insight(attrs \\ %{}) do
    %AnalysisInsight{}
    |> AnalysisInsight.changeset(attrs)
    |> Repo.insert()
  end

  def import_run(fight_id, attrs) when is_integer(fight_id) do
    ImportRun.call(fight_id, attrs)
  end

  defp participant_matches_character?(
         participant,
         normalized_realm,
         normalized_realm_slug,
         normalized_class,
         normalized_spec
       ) do
    realm_match? =
      case normalize_identity_segment(participant.server_name) do
        nil ->
          true

        normalized_server_name ->
          normalized_server_name in [normalized_realm, normalized_realm_slug]
      end

    class_match? =
      identity_matches?(participant.class_name, normalized_class)

    spec_match? =
      identity_matches?(participant.spec_name, normalized_spec)

    realm_match? and class_match? and spec_match?
  end

  defp identity_matches?(_value, nil), do: true

  defp identity_matches?(value, normalized_expected) do
    case normalize_identity_segment(value) do
      nil -> true
      normalized_value -> normalized_value == normalized_expected
    end
  end

  defp insights_query do
    from(insight in AnalysisInsight,
      order_by: [
        desc: insight.highlighted,
        desc: insight.impact_score,
        asc: insight.display_order
      ]
    )
  end

  defp normalize_identity_segment(nil), do: nil

  defp normalize_identity_segment(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end
end
