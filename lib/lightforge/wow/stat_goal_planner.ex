defmodule Lightforge.Wow.StatGoalPlanner do
  @moduledoc false

  @reviewed_on ~D[2026-03-10]

  @holy_goals [
    %{
      key: :haste,
      label: "Haste",
      note: "Primary Holy Paladin throughput and flow stat in current Midnight guidance.",
      minimum_target_value: 30.0,
      target_display: "30-40%",
      target_value: 35.0
    },
    %{
      key: :crit,
      label: "Critical Strike",
      note: "Useful support stat once Haste is healthy in current Holy Paladin builds.",
      minimum_target_value: 18.0,
      target_display: "18-22%",
      target_value: 20.0
    },
    %{
      key: :versatility,
      label: "Versatility",
      note: "Low but valuable support stat for damage and survival in pre-season play.",
      minimum_target_value: 10.0,
      target_display: "10-14%",
      target_value: 12.0
    },
    %{
      key: :mastery,
      label: "Mastery",
      note: "Keep this flexible rather than forcing it ahead of the current priority trio.",
      minimum_target_value: 15.0,
      target_display: "15-20%",
      target_value: 18.0
    }
  ]

  def build("Paladin", "Holy", stat_lines) when is_list(stat_lines) do
    %{
      note:
        "These bars use Lightforge goal bands inferred from current Holy Paladin Midnight guidance and top-profile trends. Treat them as practical targets, not exact caps.",
      reviewed_on: @reviewed_on,
      source_name: "Method + WingsIsUp",
      source_url: "https://www.method.gg/guides/holy-paladin/playstyle-and-rotation",
      goals: Enum.map(@holy_goals, &normalize_goal(&1, stat_lines))
    }
  end

  def build(_character_class, _spec_name, _stat_lines), do: nil

  defp normalize_goal(goal, stat_lines) do
    stat =
      Enum.find(stat_lines, fn stat_line ->
        Map.get(stat_line, :key) == goal.key
      end)

    current_value = if is_map(stat), do: Map.get(stat, :raw_value), else: nil

    Map.merge(goal, %{
      current_display: current_display(current_value),
      current_value: current_value,
      progress: progress(current_value, goal.minimum_target_value)
    })
  end

  defp current_display(value) when is_integer(value), do: "#{value}%"

  defp current_display(value) when is_float(value) do
    "#{Float.round(value, 2)}%"
  end

  defp current_display(_value), do: "Unavailable"

  defp progress(value, target_value)
       when is_number(value) and is_number(target_value) and target_value > 0 do
    value
    |> Kernel./(target_value)
    |> Kernel.*(100)
    |> min(100.0)
    |> Float.round(1)
  end

  defp progress(_value, _target_value), do: 0.0
end
