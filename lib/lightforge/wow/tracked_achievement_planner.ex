defmodule Lightforge.Wow.TrackedAchievementPlanner do
  @moduledoc false

  @season_one_start ~D[2026-03-17]
  @keystone_start ~D[2026-03-24]

  def build(attrs, today \\ Date.utc_today()) when is_map(attrs) do
    [
      aotc_goal(today),
      keystone_master_goal(today),
      holy_paladin_quest_goal(attrs),
      legendary_goal(today)
    ]
  end

  defp aotc_goal(today) do
    if Date.compare(today, @season_one_start) == :lt do
      %{
        title: "Ahead of the Curve",
        status: "Locked",
        detail: "Heroic raid progression is not active yet in the Midnight pre-season window.",
        next_action:
          "Use the time before March 17, 2026 to finish campaign progress and enter Season 1 raid-ready."
      }
    else
      %{
        title: "Ahead of the Curve",
        status: "Active",
        detail: "Season 1 heroic raid progression is now the real AOTC track.",
        next_action:
          "Start logging boss progression and wire encounter-specific kill tracking next."
      }
    end
  end

  defp keystone_master_goal(today) do
    if Date.compare(today, @keystone_start) == :lt do
      %{
        title: "Keystone Master",
        status: "Locked",
        detail: "Mythic+ keystones are not part of the Midnight pre-season yet.",
        next_action:
          "Use the time before March 24, 2026 to learn routes, tighten cooldown plans, and be ready when score actually matters."
      }
    else
      %{
        title: "Keystone Master",
        status: "Active",
        detail: "Seasonal Mythic+ progression is now live.",
        next_action:
          "Track live Mythic+ score against the 2000 benchmark in the next planner pass."
      }
    end
  end

  defp holy_paladin_quest_goal(%{character_class: "Paladin", active_spec: "Holy"}) do
    %{
      title: "Holy Paladin Quest Progress",
      status: "Manual",
      detail:
        "Quest-specific Holy Paladin progression is not exposed cleanly in the current Battle.net slice.",
      next_action:
        "Use this goal as your weekly checkpoint until class or quest-state tracking is added."
    }
  end

  defp holy_paladin_quest_goal(_attrs) do
    %{
      title: "Spec Quest Progress",
      status: "Manual",
      detail:
        "Spec-specific quest progression is not exposed cleanly in the current Battle.net slice.",
      next_action: "Leave this as a manual checkpoint until quest-state tracking is added."
    }
  end

  defp legendary_goal(today) do
    if Date.compare(today, @season_one_start) == :lt do
      %{
        title: "Legendary Item Progression",
        status: "Coming soon",
        detail:
          "Legendary progression is not something Lightforge can read from Battle.net yet during pre-season.",
        next_action:
          "Keep campaign and launch progression current so you are ready when the legendary path becomes relevant."
      }
    else
      %{
        title: "Legendary Item Progression",
        status: "Pending tracking",
        detail:
          "The goal matters, but the exact progression chain still needs a dedicated tracker.",
        next_action: "Add quest-state or item-chain tracking once the legendary route is stable."
      }
    end
  end
end
