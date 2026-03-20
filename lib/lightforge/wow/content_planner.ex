defmodule Lightforge.Wow.ContentPlanner do
  @moduledoc false

  @season_one_start ~D[2026-03-17]
  @darkway_open ~D[2026-03-24]
  @parhelion_plaza_open ~D[2026-03-31]

  def build(attrs, today \\ Date.utc_today()) when is_map(attrs) do
    mythic_summary = Map.get(attrs, :mythic_summary) || %{}
    achievement_summary = Map.get(attrs, :achievement_summary) || %{}

    %{
      actions: build_actions(attrs, mythic_summary, achievement_summary, today),
      milestones: build_milestones(attrs, mythic_summary, achievement_summary, today),
      rows: build_rows(attrs, mythic_summary, achievement_summary, today)
    }
  end

  defp build_rows(attrs, mythic_summary, achievement_summary, today) do
    [
      %{
        label: "Phase",
        value: phase_label(today),
        detail: phase_detail(today)
      },
      %{
        label: "Dungeon track",
        value: dungeon_track_value(mythic_summary, today),
        detail: dungeon_track_detail(mythic_summary, today)
      },
      %{
        label: "Delves",
        value: delve_value(today),
        detail: delve_detail(today)
      },
      %{
        label: "Achievements",
        value: achievement_value(achievement_summary),
        detail: achievement_detail(achievement_summary)
      },
      %{
        label: "Readiness",
        value: readiness_value(Map.get(attrs, :equipped_item_level)),
        detail: readiness_detail(today)
      }
    ]
  end

  defp build_actions(attrs, mythic_summary, achievement_summary, today) do
    recent_count = Map.get(achievement_summary, :recent_count)

    [
      %{
        title: "Finish Midnight campaign",
        detail:
          if Date.compare(today, @season_one_start) == :lt do
            "Use the pre-season window to finish the launch campaign before Season 1 opens on March 17, 2026."
          else
            "Keep campaign progression current so your weekly activities stay unlocked as Season 1 expands."
          end
      },
      %{
        title: dungeon_action_title(mythic_summary, today),
        detail: dungeon_action_detail(mythic_summary, today)
      },
      %{
        title: "Push launch delves",
        detail: delve_action_detail(today)
      },
      %{
        title: "Keep one achievement goal active",
        detail:
          if is_integer(recent_count) and recent_count > 0 do
            "You already have recent achievement movement. Keep one Midnight-specific goal pinned so the cockpit stays useful for both progression and completion."
          else
            "Pick one Midnight achievement thread now so progress does not stay purely gear-driven during the pre-season gap."
          end
      }
    ]
    |> maybe_add_holy_paladin_action(attrs)
  end

  defp build_milestones(attrs, mythic_summary, achievement_summary, today) do
    [
      %{
        title: "Season phase",
        value: phase_label(today),
        detail: phase_detail(today)
      },
      %{
        title: "Dungeon readiness",
        value: dungeon_milestone_value(mythic_summary, today),
        detail: dungeon_track_detail(mythic_summary, today)
      },
      %{
        title: "Delve rollout",
        value: delve_milestone_value(today),
        detail: delve_detail(today)
      },
      %{
        title: "Achievement momentum",
        value: achievement_milestone_value(achievement_summary),
        detail: achievement_detail(achievement_summary)
      },
      %{
        title: "Character focus",
        value: focus_value(attrs),
        detail: focus_detail(attrs)
      }
    ]
  end

  defp maybe_add_holy_paladin_action(actions, %{character_class: "Paladin", active_spec: "Holy"}) do
    actions ++
      [
        %{
          title: "Secure your Holy Paladin bridge set",
          detail:
            "Keep using the pre-season Holy plan as a bridge only. Replace it with real Season 1 targets once March 17, 2026 arrives."
        }
      ]
  end

  defp maybe_add_holy_paladin_action(actions, _attrs), do: actions

  defp phase_label(today) do
    if Date.compare(today, @season_one_start) == :lt,
      do: "Midnight pre-season",
      else: "Midnight Season 1"
  end

  defp phase_detail(today) do
    if Date.compare(today, @season_one_start) == :lt do
      "Season 1 opens March 17, 2026."
    else
      "Season 1 is live. Weekly dungeon and raid planning should now take priority."
    end
  end

  defp dungeon_track_value(%{best_key: nil}, today) do
    if Date.compare(today, @season_one_start) == :lt do
      "No tracked dungeon clears yet"
    else
      "No Mythic+ route tracked yet"
    end
  end

  defp dungeon_track_value(%{best_key: key, best_dungeon: dungeon}, today) when is_integer(key) do
    if Date.compare(today, @season_one_start) == :lt do
      "Best tracked run: +#{key}#{dungeon_suffix(dungeon)}"
    else
      "Best key: +#{key}#{dungeon_suffix(dungeon)}"
    end
  end

  defp dungeon_track_value(_mythic_summary, _today), do: "No tracked dungeon activity"

  defp dungeon_track_detail(%{best_key: nil}, today) do
    if Date.compare(today, @season_one_start) == :lt do
      "Use the launch window to get comfortable with the Midnight dungeon pool before Season 1 starts."
    else
      "Start building your weekly route and vault baseline."
    end
  end

  defp dungeon_track_detail(%{run_count: run_count}, today) do
    runs = if is_integer(run_count), do: run_count, else: 0

    if Date.compare(today, @season_one_start) == :lt do
      "#{runs} tracked run(s) recorded in the current profile snapshot."
    else
      "#{runs} tracked seasonal run(s) recorded in the current profile snapshot."
    end
  end

  defp delve_value(today) do
    cond do
      Date.compare(today, @darkway_open) == :lt ->
        "Launch delve set active"

      Date.compare(today, @parhelion_plaza_open) == :lt ->
        "Darkway unlocked"

      true ->
        "Darkway and Parhelion Plaza unlocked"
    end
  end

  defp delve_detail(today) do
    cond do
      Date.compare(today, @darkway_open) == :lt ->
        "The Darkway unlocks on March 24, 2026. Parhelion Plaza unlocks on March 31, 2026."

      Date.compare(today, @parhelion_plaza_open) == :lt ->
        "The Darkway is live. Parhelion Plaza unlocks on March 31, 2026."

      true ->
        "All currently announced Midnight launch delves are available."
    end
  end

  defp achievement_value(%{points: points}) when is_integer(points), do: "#{points} points"
  defp achievement_value(_achievement_summary), do: "Points unavailable"

  defp achievement_detail(%{recent_count: count}) when is_integer(count) do
    "#{count} recent achievement event(s) in the linked Battle.net profile."
  end

  defp achievement_detail(_achievement_summary), do: "Recent achievement activity unavailable."

  defp readiness_value(item_level) when is_integer(item_level), do: "ilvl #{item_level}"
  defp readiness_value(_item_level), do: "Item level unavailable"

  defp readiness_detail(today) do
    if Date.compare(today, @season_one_start) == :lt do
      "Use this week to smooth out weak slots and be ready to pivot once Season 1 loot becomes available."
    else
      "Shift from launch smoothing to exact seasonal upgrade planning."
    end
  end

  defp dungeon_action_title(%{best_key: nil}, today) do
    if Date.compare(today, @season_one_start) == :lt do
      "Start the launch dungeon circuit"
    else
      "Start your weekly Mythic+ route"
    end
  end

  defp dungeon_action_title(_mythic_summary, today) do
    if Date.compare(today, @season_one_start) == :lt do
      "Keep dungeon familiarity high"
    else
      "Push your next key threshold"
    end
  end

  defp dungeon_action_detail(%{best_key: nil}, today) do
    if Date.compare(today, @season_one_start) == :lt do
      "Run the launch dungeon pool now so your routing and role cadence are clean before March 17, 2026."
    else
      "Get at least one meaningful seasonal key on the board for routing and weekly planning."
    end
  end

  defp dungeon_action_detail(%{best_key: key}, today) when is_integer(key) do
    if Date.compare(today, @season_one_start) == :lt do
      "You already have tracked dungeon activity. Use the remaining pre-season window to tighten execution rather than broad farming."
    else
      "Your current best key is +#{key}. Push the next threshold that meaningfully upgrades your weekly options."
    end
  end

  defp dungeon_action_detail(_mythic_summary, _today),
    do: "Use current dungeon data to keep your weekly route purposeful."

  defp delve_action_detail(today) do
    cond do
      Date.compare(today, @darkway_open) == :lt ->
        "Work through the launch delve set now. Darkway opens on March 24, 2026 and Parhelion Plaza follows on March 31, 2026."

      Date.compare(today, @parhelion_plaza_open) == :lt ->
        "Add Darkway into your delve loop now and be ready to fold in Parhelion Plaza on March 31, 2026."

      true ->
        "All currently announced launch delves are available, so you can turn this into a consistent weekly track."
    end
  end

  defp dungeon_milestone_value(%{best_key: nil}, today) do
    if Date.compare(today, @season_one_start) == :lt, do: "Pre-season prep", else: "Not started"
  end

  defp dungeon_milestone_value(%{best_key: key}, _today) when is_integer(key),
    do: "+#{key} tracked"

  defp dungeon_milestone_value(_mythic_summary, _today), do: "Unavailable"

  defp delve_milestone_value(today) do
    cond do
      Date.compare(today, @darkway_open) == :lt -> "Launch set only"
      Date.compare(today, @parhelion_plaza_open) == :lt -> "Darkway live"
      true -> "Expanded launch set live"
    end
  end

  defp achievement_milestone_value(%{recent_count: count}) when is_integer(count) and count > 0,
    do: "#{count} recent events"

  defp achievement_milestone_value(%{recent_count: 0}), do: "No recent events"
  defp achievement_milestone_value(_achievement_summary), do: "Unavailable"

  defp focus_value(%{character_class: class_name, active_spec: spec_name})
       when is_binary(class_name) and is_binary(spec_name),
       do: "#{spec_name} #{class_name}"

  defp focus_value(%{character_class: class_name}) when is_binary(class_name), do: class_name
  defp focus_value(_attrs), do: "Character focus unavailable"

  defp focus_detail(%{equipped_item_level: item_level}) when is_integer(item_level),
    do: "Current equipped item level is #{item_level}."

  defp focus_detail(_attrs), do: "Equipped item level unavailable."

  defp dungeon_suffix(dungeon) when is_binary(dungeon) and dungeon != "", do: " in #{dungeon}"
  defp dungeon_suffix(_dungeon), do: ""
end
