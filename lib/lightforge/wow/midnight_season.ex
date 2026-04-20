defmodule Lightforge.Wow.MidnightSeason do
  @moduledoc false

  @season_one_start ~D[2026-03-17]
  @keystone_start ~D[2026-03-24]
  @darkway_open ~D[2026-03-24]
  @parhelion_plaza_open ~D[2026-03-31]

  @item_level_cap 289
  @focused_readiness 275
  @selective_readiness 280

  @campaign_target_hint 272
  @dungeon_target_hint 276
  @raid_target_hint 282

  @major_upgrade_gap 6
  @solid_upgrade_gap 3
  @keystone_master_score 2000.0

  @mythic_plus_dungeons [
    "Maisara Caverns",
    "Magisters' Terrace",
    "Nexus-Point Xenas",
    "Windrunner Spire",
    "Algeth'ar Academy",
    "Pit of Saron",
    "Seat of the Triumvirate",
    "Skyreach"
  ]

  @mythic_plus_aliases %{
    "Magister's Terrace" => "Magisters' Terrace"
  }

  @raid_bosses [
    "Imperator Averzian",
    "Vorasius",
    "Fallen-King Salhadaar",
    "Vaelgor & Ezzorak",
    "Lightblinded Vanguard",
    "Crown of the Cosmos",
    "Chimaerus, the Undreamt God",
    "Belo'ren, Child of Al'ar",
    "Midnight Falls"
  ]

  def season_one_start, do: @season_one_start
  def keystone_start, do: @keystone_start
  def darkway_open, do: @darkway_open
  def parhelion_plaza_open, do: @parhelion_plaza_open

  def item_level_cap, do: @item_level_cap
  def focused_readiness, do: @focused_readiness
  def selective_readiness, do: @selective_readiness

  def campaign_target_hint, do: @campaign_target_hint
  def dungeon_target_hint, do: @dungeon_target_hint
  def raid_target_hint, do: @raid_target_hint

  def major_upgrade_gap, do: @major_upgrade_gap
  def solid_upgrade_gap, do: @solid_upgrade_gap
  def keystone_master_score, do: @keystone_master_score

  def mythic_plus_dungeons, do: @mythic_plus_dungeons
  def raid_bosses, do: @raid_bosses

  def normalize_mythic_plus_dungeon(name) when is_binary(name) do
    Map.get(@mythic_plus_aliases, name, name)
  end

  def normalize_mythic_plus_dungeon(name), do: name

  def mythic_plus_dungeon?(name) do
    normalize_mythic_plus_dungeon(name) in @mythic_plus_dungeons
  end

  def season_live?(today \\ Date.utc_today()) do
    Date.compare(today, @season_one_start) != :lt
  end

  def keystones_live?(today \\ Date.utc_today()) do
    Date.compare(today, @keystone_start) != :lt
  end

  def phase_label(today \\ Date.utc_today()) do
    if season_live?(today), do: "Midnight Season 1", else: "Midnight pre-season"
  end

  def readiness_band(item_level) when is_integer(item_level) do
    cond do
      item_level >= @selective_readiness -> :selective
      item_level >= @focused_readiness -> :focused
      true -> :catch_up
    end
  end

  def readiness_band(_item_level), do: :unknown

  def vault_options(run_count) when is_integer(run_count) and run_count >= 8, do: 3
  def vault_options(run_count) when is_integer(run_count) and run_count >= 4, do: 2
  def vault_options(run_count) when is_integer(run_count) and run_count >= 1, do: 1
  def vault_options(_run_count), do: 0
end
