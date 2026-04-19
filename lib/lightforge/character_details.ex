defmodule Lightforge.CharacterDetails do
  @moduledoc false

  alias Lightforge.Analysis
  alias Lightforge.Characters
  alias Lightforge.Gearing.Recommendation

  def get_character_detail(region, realm, name) do
    with character when not is_nil(character) <-
           Characters.get_character_by_identity(region, realm, name),
         snapshot when not is_nil(snapshot) <- Characters.get_latest_snapshot(character) do
      {:ok,
       %{
         analysis: serialize_analysis(Analysis.get_latest_run_for_character(character)),
         character: serialize_character(character),
         gearing: serialize_gearing(Recommendation.build(character, snapshot, "dungeons")),
         items: Enum.map(snapshot.gear_snapshot_items, &serialize_gear_item/1),
         snapshot: serialize_snapshot(snapshot)
       }}
    else
      nil -> {:error, :not_found}
    end
  end

  defp serialize_character(character) do
    %{
      class_name: character.class_name,
      faction_name: character.faction_name,
      id: character.id,
      level: character.level,
      name: character.name,
      region: character.region,
      realm: character.realm,
      realm_slug: character.realm_slug,
      spec_name: character.spec_name
    }
  end

  defp serialize_snapshot(snapshot) do
    %{
      achievements_json: snapshot.achievements_json,
      captured_at: snapshot.captured_at,
      character_id: snapshot.character_id,
      equipped_item_level: snapshot.equipped_item_level,
      gear_item_count: length(snapshot.gear_snapshot_items),
      id: snapshot.id,
      media_json: snapshot.media_json,
      mythic_json: snapshot.mythic_json,
      profile_json: snapshot.profile_json,
      statistics_json: snapshot.statistics_json
    }
  end

  defp serialize_gear_item(item) do
    %{
      blizzard_item_id: item.blizzard_item_id,
      icon_url: item.icon_url,
      inventory_type: item.inventory_type,
      item_level: item.item_level,
      item_name: item.item_name,
      quality: item.quality,
      slot_key: item.slot_key,
      slot_name: item.slot_name
    }
  end

  defp serialize_analysis(nil), do: nil

  defp serialize_analysis(run) do
    %{
      fight: %{
        difficulty: run.fight && run.fight.difficulty,
        encounter_name: run.fight && run.fight.encounter_name,
        kill: run.fight && run.fight.kill,
        report_code: run.fight && run.fight.report && run.fight.report.code
      },
      finished_at: run.finished_at,
      id: run.id,
      insights: Enum.map(run.insights, &serialize_insight/1),
      participant: %{
        class_name: run.participant && run.participant.class_name,
        item_level: run.participant && run.participant.item_level,
        name: run.participant && run.participant.name,
        role: run.participant && run.participant.role,
        server_name: run.participant && run.participant.server_name,
        spec_name: run.participant && run.participant.spec_name
      },
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
      provider: insight.provider,
      recommendation: insight.recommendation,
      severity: insight.severity,
      source_key: insight.source_key,
      summary: insight.summary,
      title: insight.title
    }
  end

  defp serialize_gearing(plan) do
    %{
      current_trinkets: plan.current_trinkets,
      meta: plan.meta,
      mode: plan.mode,
      pending: plan.pending,
      priority_slots: plan.priority_slots,
      stat_direction: plan.stat_direction,
      summary: plan.summary,
      top_targets: plan.top_targets,
      weekly_route: plan.weekly_route
    }
  end
end
