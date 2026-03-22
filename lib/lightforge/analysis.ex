defmodule Lightforge.Analysis do
  @moduledoc """
  Persistence-facing context for encounter analysis runs and actionable insights.

  The intention is to store provider-specific output, such as future
  WoWAnalyzer-derived recommendations, in a form that is already filtered,
  ranked, and easy for the frontend to present.
  """

  import Ecto.Query, only: [from: 2]

  alias Lightforge.Analysis.AnalysisInsight
  alias Lightforge.Analysis.ImportRun
  alias Lightforge.Analysis.AnalysisRun
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

  def get_latest_run_for_fight_and_participant(%Fight{id: fight_id}, %Participant{id: participant_id}) do
    from(run in AnalysisRun,
      where: run.fight_id == ^fight_id and run.participant_id == ^participant_id,
      order_by: [desc: run.inserted_at],
      limit: 1,
      preload: [:participant, :insights]
    )
    |> Repo.one()
  end

  def list_insights_for_run(%AnalysisRun{id: run_id}) do
    from(insight in AnalysisInsight,
      where: insight.analysis_run_id == ^run_id,
      order_by: [desc: insight.highlighted, desc: insight.impact_score, asc: insight.display_order]
    )
    |> Repo.all()
  end

  def list_insights_for_fight(%Fight{id: fight_id}) do
    from(insight in AnalysisInsight,
      where: insight.fight_id == ^fight_id,
      order_by: [desc: insight.highlighted, desc: insight.impact_score, asc: insight.display_order]
    )
    |> Repo.all()
  end

  def list_insights_for_participant(%Participant{id: participant_id}) do
    from(insight in AnalysisInsight,
      where: insight.participant_id == ^participant_id,
      order_by: [desc: insight.highlighted, desc: insight.impact_score, asc: insight.display_order]
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
end
