defmodule Lightforge.Wow.ProgressionPlanner do
  @moduledoc false

  alias Lightforge.Wow.MidnightSeason

  def build(attrs) when is_map(attrs) do
    mythic_summary = Map.get(attrs, :mythic_summary) || %{}

    %{
      tracks: [
        mythic_track(mythic_summary),
        raid_track()
      ]
    }
  end

  def build(_attrs), do: %{tracks: [mythic_track(%{}), raid_track()]}

  defp mythic_track(mythic_summary) do
    dungeon_runs =
      mythic_summary
      |> Map.get(:dungeon_runs, [])
      |> Map.new(fn dungeon ->
        {MidnightSeason.normalize_mythic_plus_dungeon(dungeon.name), dungeon.key_level}
      end)

    %{
      badges:
        Enum.map(MidnightSeason.mythic_plus_dungeons(), fn dungeon_name ->
          %{
            label: dungeon_name,
            state: mythic_badge_state(Map.get(dungeon_runs, dungeon_name)),
            value: mythic_badge_value(Map.get(dungeon_runs, dungeon_name))
          }
        end),
      key: :mythic_plus,
      label: "M+"
    }
  end

  defp raid_track do
    %{
      badges:
        Enum.map(MidnightSeason.raid_bosses(), fn boss_name ->
          %{
            label: boss_name,
            state: :pending,
            value: "?"
          }
        end),
      key: :raid,
      label: "Raid"
    }
  end

  defp mythic_badge_value(key_level) when is_integer(key_level), do: "+#{key_level}"
  defp mythic_badge_value(_key_level), do: "--"

  defp mythic_badge_state(key_level) when is_integer(key_level) and key_level >= 12, do: :orange
  defp mythic_badge_state(key_level) when is_integer(key_level) and key_level >= 10, do: :purple
  defp mythic_badge_state(key_level) when is_integer(key_level) and key_level >= 7, do: :blue
  defp mythic_badge_state(key_level) when is_integer(key_level) and key_level >= 2, do: :green
  defp mythic_badge_state(_key_level), do: :pending
end
