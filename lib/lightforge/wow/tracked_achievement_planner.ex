defmodule Lightforge.Wow.TrackedAchievementPlanner do
  @moduledoc false

  alias Lightforge.Wow.MidnightSeason

  def build(attrs, today \\ Date.utc_today()) when is_map(attrs) do
    [
      aotc_goal(today),
      keystone_master_goal(attrs, today),
      holy_paladin_quest_goal(attrs),
      legendary_goal(today)
    ]
  end

  defp aotc_goal(today) do
    if MidnightSeason.season_live?(today) do
      %{
        title: "Ahead of the Curve",
        status: "Tracking needed",
        detail:
          "Season 1 heroic raid progression is live, but Lightforge is not yet reading boss-kill completion from Battle.net.",
        next_action:
          "Show raid kill progress here once encounter or achievement-level tracking is wired."
      }
    else
      %{
        title: "Ahead of the Curve",
        status: "Locked",
        detail: "Heroic raid progression is not active yet in the Midnight pre-season window.",
        next_action:
          "Use the time before March 17, 2026 to finish campaign progress and enter Season 1 raid-ready."
      }
    end
  end

  defp keystone_master_goal(attrs, today) do
    score = get_in(attrs, [:mythic_summary, :score])

    cond do
      not MidnightSeason.keystones_live?(today) ->
        %{
          title: "Keystone Master",
          status: "Locked",
          detail: "Mythic+ keystones are not part of the Midnight pre-season yet.",
          next_action:
            "Use the time before March 24, 2026 to learn routes, tighten cooldown plans, and be ready when score actually matters."
        }

      is_number(score) and score >= MidnightSeason.keystone_master_score() ->
        %{
          title: "Keystone Master",
          status: "Earned",
          detail: "Your current Mythic+ score is high enough to satisfy the 2000 benchmark.",
          next_action:
            "Shift focus from the score floor to vault quality and targeted slot upgrades."
        }

      is_number(score) ->
        remaining = Float.round(MidnightSeason.keystone_master_score() - score, 1)

        %{
          title: "Keystone Master",
          status: "In progress",
          detail:
            "Your current Mythic+ score is #{Float.round(score, 1)}. You still need #{remaining} score to reach 2000.",
          next_action:
            "Push the next score threshold rather than spreading effort across low-value keys."
        }

      true ->
        %{
          title: "Keystone Master",
          status: "Tracking needed",
          detail:
            "Seasonal Mythic+ progression is live, but score is unavailable in the current snapshot.",
          next_action: "Refresh the character snapshot so score-driven KSM tracking can render."
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
    if MidnightSeason.season_live?(today) do
      %{
        title: "Legendary Item Progression",
        status: "Pending tracking",
        detail:
          "The goal matters, but the exact progression chain still needs a dedicated tracker.",
        next_action: "Add quest-state or item-chain tracking once the legendary route is stable."
      }
    else
      %{
        title: "Legendary Item Progression",
        status: "Coming soon",
        detail:
          "Legendary progression is not something Lightforge can read from Battle.net yet during pre-season.",
        next_action:
          "Keep campaign and launch progression current so you are ready when the legendary path becomes relevant."
      }
    end
  end
end
