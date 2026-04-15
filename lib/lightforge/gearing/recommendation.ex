defmodule Lightforge.Gearing.Recommendation do
  @moduledoc false

  alias Lightforge.Characters.Character
  alias Lightforge.Characters.CharacterSnapshot
  alias Lightforge.Gearing.Curation
  alias Lightforge.Wow.MidnightSeason
  alias Lightforge.Wow.SpecPriority
  alias Lightforge.Wow.StatGoalPlanner

  def build(%Character{} = character, %CharacterSnapshot{} = snapshot, mode) do
    mode = normalize_mode(mode)
    curation = Curation.for_character(character.class_name, character.spec_name, mode)
    stat_lines = normalize_stat_lines(snapshot.statistics_json)
    top_targets = build_top_targets(snapshot.gear_snapshot_items, curation)
    priority_slots = build_priority_slots(top_targets)

    %{
      character: %{
        class_name: character.class_name,
        level: character.level,
        name: character.name,
        region: character.region,
        realm: character.realm,
        spec_name: character.spec_name
      },
      current_trinkets: serialize_current_trinkets(snapshot.gear_snapshot_items),
      meta: build_meta(curation),
      mode: mode,
      pending: is_nil(curation),
      priority_slots: priority_slots,
      progression: build_progression(snapshot.mythic_json),
      snapshot: %{
        captured_at: DateTime.to_iso8601(snapshot.captured_at),
        equipped_item_level: snapshot.equipped_item_level,
        id: snapshot.id
      },
      stat_direction: build_stat_direction(character, stat_lines, mode),
      summary: build_summary(character, curation, mode, top_targets, priority_slots),
      top_targets: top_targets,
      weekly_route: build_weekly_route(mode, top_targets)
    }
  end

  defp build_meta(nil) do
    %{
      note: "Curated item targets for this spec and mode are not published yet.",
      reviewed_on: nil,
      season: "Midnight Season 1",
      source_name: "Lightforge curation"
    }
  end

  defp build_meta(curation) do
    %{
      note: curation.note,
      reviewed_on: Date.to_iso8601(curation.reviewed_on),
      season: curation.season,
      source_name: curation.source_name
    }
  end

  defp build_top_targets(_items, nil), do: []

  defp build_top_targets(items, curation) do
    curation.targets
    |> Enum.map(&enrich_target(&1, items))
    |> Enum.sort_by(& &1.priority)
  end

  defp enrich_target(target, items) do
    current_items =
      items
      |> Enum.filter(&(&1.slot_key in target.slot_keys))
      |> Enum.sort_by(&slot_index(&1.slot_key))

    current_level = current_level(current_items)
    matched? = Enum.any?(current_items, &same_item_name?(&1.item_name, target.target_name))

    %{
      current_item_level: current_level,
      current_item_name: current_label(current_items),
      priority: target.priority,
      reason: target.reason,
      slot: target.slot_label,
      source_name: target.source_name,
      source_type: target.source_type,
      status: target_status(matched?, current_level, target.target_item_level_hint),
      target_item_level_hint: target.target_item_level_hint,
      target_name: target.target_name,
      tier: target.tier
    }
  end

  defp build_priority_slots(top_targets) do
    top_targets
    |> Enum.reject(&(&1.status == "owned"))
    |> Enum.group_by(& &1.slot)
    |> Enum.map(fn {slot, targets} ->
      target = Enum.min_by(targets, & &1.priority)

      %{
        current_item_level: target.current_item_level,
        priority: target.priority,
        reason: priority_reason(target),
        slot: slot,
        urgency: slot_urgency(target)
      }
    end)
    |> Enum.sort_by(&priority_slot_order/1)
    |> Enum.take(4)
    |> Enum.map(&Map.delete(&1, :priority))
  end

  defp build_weekly_route(_mode, []), do: []

  defp build_weekly_route(mode, top_targets) do
    top_targets
    |> Enum.reject(&(&1.status == "owned"))
    |> Enum.uniq_by(& &1.source_name)
    |> Enum.take(3)
    |> Enum.map(fn target ->
      %{
        label: weekly_label(mode, target.source_name),
        reason: target.reason,
        source_name: target.source_name,
        source_type: target.source_type
      }
    end)
  end

  defp weekly_label("raid", source_name), do: "Prioritize #{source_name}"
  defp weekly_label(_mode, source_name), do: "Run #{source_name} first"

  defp build_summary(character, nil, mode, _top_targets, _priority_slots) do
    spec_label =
      [character.spec_name, character.class_name]
      |> Enum.filter(&is_binary/1)
      |> Enum.join(" ")

    %{
      headline:
        "Curated #{mode_label(mode)} path is not ready for #{blank_fallback(spec_label)} yet.",
      subheadline:
        "The page still surfaces your current trinkets and stat direction from the latest character snapshot."
    }
  end

  defp build_summary(_character, _curation, mode, top_targets, priority_slots) do
    urgent_count = Enum.count(priority_slots, &(&1.urgency == "fix_now"))
    live_targets = Enum.count(top_targets, &(&1.status != "owned"))

    headline =
      cond do
        urgent_count >= 2 ->
          "You have #{urgent_count} high-impact slots to fix before broad farming."

        live_targets > 0 ->
          "#{live_targets} curated #{mode_label(mode)} target(s) are worth chasing right now."

        true ->
          "Your current route is mostly stable. Chase selective upgrades only."
      end

    subheadline =
      case Enum.take(priority_slots, 2) do
        [] ->
          "This route is intentionally short so the next upgrade decision stays obvious."

        slots ->
          "Start with #{Enum.map_join(slots, " and ", &String.downcase(&1.slot))} before spreading effort across lower-value slots."
      end

    %{
      headline: headline,
      subheadline: subheadline
    }
  end

  defp build_stat_direction(character, stat_lines, mode) do
    goal_plan = StatGoalPlanner.build(character.class_name, character.spec_name, stat_lines)
    priority = SpecPriority.for_character(character.class_name, character.spec_name)

    cond do
      goal_plan ->
        goals =
          goal_plan.goals
          |> Enum.sort_by(&goal_gap/1, :desc)
          |> Enum.take(2)
          |> Enum.map(fn goal ->
            %{
              current_display: goal.current_display,
              label: goal.label,
              progress: goal.progress,
              target_display: goal.target_display
            }
          end)

        %{
          current: Enum.map(stat_lines, &serialize_stat_line/1),
          focus: goals,
          mode: mode,
          note: goal_plan.note,
          reviewed_on: Date.to_iso8601(goal_plan.reviewed_on),
          source_name: goal_plan.source_name,
          source_url: goal_plan.source_url
        }

      priority ->
        focus =
          priority.priorities
          |> Enum.take(2)
          |> Enum.map(fn stat ->
            current =
              Enum.find(stat_lines, fn stat_line ->
                stat_line.key == stat.key
              end)

            %{
              current_display: current_display(current),
              label: stat.label,
              target_display: stat.target,
              progress: nil
            }
          end)

        %{
          current: Enum.map(stat_lines, &serialize_stat_line/1),
          focus: focus,
          mode: priority.mode,
          note: priority.note,
          reviewed_on: Date.to_iso8601(priority.reviewed_on),
          source_name: priority.source_name,
          source_url: priority.source_url
        }

      true ->
        nil
    end
  end

  defp current_display(nil), do: "Unavailable"
  defp current_display(stat_line), do: stat_line.display

  defp serialize_stat_line(stat_line) do
    %{
      display: stat_line.display,
      label: stat_line.label
    }
  end

  defp serialize_current_trinkets(items) do
    items
    |> Enum.filter(&String.contains?(to_string(&1.slot_key), "TRINKET"))
    |> Enum.map(fn item ->
      %{
        item_level: item.item_level,
        item_name: item.item_name,
        slot: item.slot_name
      }
    end)
  end

  defp goal_gap(goal) do
    current = if is_number(goal.current_value), do: goal.current_value, else: 0.0
    target = if is_number(goal.target_value), do: goal.target_value, else: 0.0
    max(target - current, 0.0)
  end

  defp normalize_mode(mode) do
    mode = to_string(mode)

    if Curation.supported_mode?(mode), do: mode, else: "dungeons"
  end

  defp normalize_stat_lines(nil), do: []

  defp normalize_stat_lines(body) when is_map(body) do
    [
      percentage_line(
        :crit,
        "Crit",
        stat_percentage(body, ["melee_crit", "spell_crit", "ranged_crit", "crit"])
      ),
      percentage_line(
        :haste,
        "Haste",
        stat_percentage(body, ["melee_haste", "spell_haste", "haste"])
      ),
      percentage_line(:mastery, "Mastery", stat_percentage(body, ["mastery"])),
      percentage_line(
        :versatility,
        "Versatility",
        stat_percentage(body, ["versatility", "versatility_damage_done_bonus"])
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_stat_lines(_body), do: []

  defp build_progression(nil), do: empty_progression()

  defp build_progression(body) when is_map(body) do
    best_runs =
      cond do
        is_list(get_in(body, ["current_period", "best_runs"])) ->
          get_in(body, ["current_period", "best_runs"])

        is_list(get_in(body, ["current_season", "best_runs"])) ->
          get_in(body, ["current_season", "best_runs"])

        is_list(body["best_runs"]) ->
          body["best_runs"]

        true ->
          []
      end

    best_key =
      best_runs
      |> Enum.map(fn run -> run["keystone_level"] || run["mythic_level"] end)
      |> Enum.filter(&is_integer/1)
      |> Enum.max(fn -> nil end)

    score =
      body["current_mythic_rating"]
      |> case do
        %{"rating" => value} when is_number(value) ->
          value * 1.0

        _ ->
          get_in(body, ["current_period", "mythic_rating", "rating"]) ||
            get_in(body, ["current_season", "mythic_rating", "rating"])
      end

    %{
      aotc: %{
        status: "Tracking needed",
        value: "Unknown"
      },
      best_key: best_key,
      keystone_master: %{
        status:
          cond do
            is_number(score) and score >= MidnightSeason.keystone_master_score() -> "Earned"
            MidnightSeason.keystones_live?() -> "In progress"
            true -> "Locked"
          end,
        value:
          cond do
            is_number(score) ->
              "#{Float.round(score, 1)} / #{trunc(MidnightSeason.keystone_master_score())}"

            true ->
              "Score unavailable"
          end
      },
      myth_vault_options: MidnightSeason.vault_options(length(best_runs)),
      raid_progression: %{
        status: "Untracked",
        value: "Boss kills unavailable"
      }
    }
  end

  defp build_progression(_body), do: empty_progression()

  defp empty_progression do
    %{
      aotc: %{status: "Tracking needed", value: "Unknown"},
      best_key: nil,
      keystone_master: %{status: "Tracking needed", value: "Score unavailable"},
      myth_vault_options: 0,
      raid_progression: %{status: "Untracked", value: "Boss kills unavailable"}
    }
  end

  defp percentage_line(_key, _label, nil), do: nil

  defp percentage_line(key, label, value) do
    rounded = Float.round(value, 2)

    %{
      display: "#{rounded}%",
      key: key,
      label: label,
      raw_value: rounded
    }
  end

  defp stat_percentage(body, keys) do
    Enum.find_value(keys, fn key ->
      case body[key] do
        %{"value" => value} when is_number(value) -> value * 1.0
        value when is_number(value) -> value * 1.0
        _ -> nil
      end
    end)
  end

  defp priority_reason(target) do
    case target.status do
      "missing" -> "No tracked item is stored for this slot yet."
      "major_upgrade" -> "Current slot is materially behind the curated target."
      "solid_upgrade" -> "A clean upgrade path exists without forcing extra loot-table sprawl."
      _ -> target.reason
    end
  end

  defp slot_urgency(target) do
    cond do
      target.slot in ["Weapon", "Trinket"] and target.status != "sidegrade" -> "fix_now"
      target.status in ["missing", "major_upgrade"] -> "fix_now"
      target.status == "solid_upgrade" -> "upgrade_next"
      true -> "fine_for_now"
    end
  end

  defp priority_slot_order(%{priority: priority, urgency: "fix_now"}), do: {0, priority}
  defp priority_slot_order(%{priority: priority, urgency: "upgrade_next"}), do: {1, priority}
  defp priority_slot_order(%{priority: priority, urgency: "fine_for_now"}), do: {2, priority}
  defp priority_slot_order(%{priority: priority}), do: {3, priority}

  defp target_status(true, _current_level, _target_level_hint), do: "owned"
  defp target_status(false, nil, _target_level_hint), do: "missing"

  defp target_status(false, current_level, target_level_hint)
       when is_integer(current_level) and is_integer(target_level_hint) do
    diff = target_level_hint - current_level

    cond do
      diff >= MidnightSeason.major_upgrade_gap() -> "major_upgrade"
      diff >= MidnightSeason.solid_upgrade_gap() -> "solid_upgrade"
      true -> "sidegrade"
    end
  end

  defp target_status(false, _current_level, _target_level_hint), do: "sidegrade"

  defp current_level(items) do
    items
    |> Enum.map(& &1.item_level)
    |> Enum.filter(&is_integer/1)
    |> Enum.max(fn -> nil end)
  end

  defp current_label([]), do: "No current item tracked"

  defp current_label(items) do
    Enum.map_join(items, " / ", fn item ->
      suffix = if is_integer(item.item_level), do: " (#{item.item_level})", else: ""
      (item.item_name || "Unknown item") <> suffix
    end)
  end

  defp same_item_name?(left, right) do
    normalize_name(left) == normalize_name(right)
  end

  defp normalize_name(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp slot_index(slot_key) do
    Enum.find_index(
      [
        "HEAD",
        "NECK",
        "SHOULDER",
        "BACK",
        "CHEST",
        "WRIST",
        "HANDS",
        "WAIST",
        "LEGS",
        "FEET",
        "FINGER_1",
        "FINGER_2",
        "TRINKET_1",
        "TRINKET_2",
        "MAIN_HAND",
        "OFF_HAND"
      ],
      &(&1 == slot_key)
    ) || 999
  end

  defp mode_label("raid"), do: "raid"
  defp mode_label(_mode), do: "dungeon"

  defp blank_fallback(""), do: "this spec"
  defp blank_fallback(value), do: value
end
