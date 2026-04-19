defmodule Lightforge.Gearing.Curation do
  @moduledoc false

  alias Lightforge.Wow.MidnightSeason

  @holy_paladin_dungeons %{
    mode: "dungeons",
    note:
      "This dungeon route keeps the surface area small: weapon, trinkets, and jewelry first, then a few stability pieces that smooth out Holy Paladin stat direction in keys on the squished Season 1 item-level scale.",
    reviewed_on: ~D[2026-04-08],
    season: "Midnight Season 1",
    source_name: "Lightforge curation",
    targets: [
      %{
        priority: 1,
        reason: "Largest immediate dungeon throughput swing if your weapon is still lagging.",
        slot_keys: ["MAIN_HAND"],
        slot_label: "Weapon",
        source_name: "Ara-Kara, City of Echoes",
        source_type: "Dungeon",
        target_item_level_hint: MidnightSeason.dungeon_target_hint(),
        target_name: "Arachnoid Soulcleaver",
        tier: "best"
      },
      %{
        priority: 2,
        reason:
          "Fast, high-impact dungeon trinket with value in both healing checks and damage windows.",
        slot_keys: ["TRINKET_1", "TRINKET_2"],
        slot_label: "Trinket",
        source_name: "The Dawnbreaker",
        source_type: "Dungeon",
        target_item_level_hint: MidnightSeason.dungeon_target_hint(),
        target_name: "Empowering Crystal of Anub'ikkaj",
        tier: "best"
      },
      %{
        priority: 3,
        reason:
          "Reliable fallback trinket when you need a practical farm target instead of a rare perfect drop.",
        slot_keys: ["TRINKET_1", "TRINKET_2"],
        slot_label: "Trinket",
        source_name: "Tazavesh",
        source_type: "Dungeon",
        target_item_level_hint: MidnightSeason.dungeon_target_hint(),
        target_name: "So'leah's Secret Technique",
        tier: "fallback"
      },
      %{
        priority: 4,
        reason:
          "Off-hand route that pairs cleanly with the dungeon weapon chase and stabilizes your weekly focus.",
        slot_keys: ["OFF_HAND"],
        slot_label: "Off-Hand",
        source_name: "Eco-Dome Al'dani",
        source_type: "Dungeon",
        target_item_level_hint: MidnightSeason.dungeon_target_hint(),
        target_name: "Starlit Safeguard",
        tier: "strong"
      },
      %{
        priority: 5,
        reason:
          "Jewelry slot that helps clean up weak stat distribution without overcomplicating the route.",
        slot_keys: ["FINGER_1", "FINGER_2"],
        slot_label: "Ring",
        source_name: "Halls of Atonement",
        source_type: "Dungeon",
        target_item_level_hint: MidnightSeason.dungeon_target_hint(),
        target_name: "Signet of the False Accuser",
        tier: "strong"
      },
      %{
        priority: 6,
        reason:
          "Easy cloak anchor for a slot that often stays neglected while trinkets and weapons get all the attention.",
        slot_keys: ["BACK"],
        slot_label: "Back",
        source_name: "Midnight campaign",
        source_type: "Campaign",
        target_item_level_hint: MidnightSeason.campaign_target_hint(),
        target_name: "Reshii Wraps",
        tier: "fallback"
      }
    ]
  }

  @holy_paladin_raid %{
    mode: "raid",
    note:
      "The raid route stays compact on purpose: secure your strongest one-handed pair, one premium trinket, and only the slots that materially change your healing profile on the live squished scale.",
    reviewed_on: ~D[2026-04-08],
    season: "Midnight Season 1",
    source_name: "Lightforge curation",
    targets: [
      %{
        priority: 1,
        reason:
          "Highest-impact raid weapon upgrade if your current main hand is behind the rest of the set.",
        slot_keys: ["MAIN_HAND"],
        slot_label: "Weapon",
        source_name: "Imperator Averzian",
        source_type: "Raid",
        target_item_level_hint: MidnightSeason.raid_target_hint(),
        target_name: "Imperator's Gilded Mace",
        tier: "best"
      },
      %{
        priority: 2,
        reason:
          "Pairs with the raid weapon route and keeps your one-hand setup clean instead of chasing scattered sidegrades.",
        slot_keys: ["OFF_HAND"],
        slot_label: "Off-Hand",
        source_name: "Lightblinded Vanguard",
        source_type: "Raid",
        target_item_level_hint: MidnightSeason.raid_target_hint(),
        target_name: "Sunward Bulwark of the Vanguard",
        tier: "strong"
      },
      %{
        priority: 3,
        reason:
          "Premium raid trinket when you want one chase piece with real ceiling instead of several middling options.",
        slot_keys: ["TRINKET_1", "TRINKET_2"],
        slot_label: "Trinket",
        source_name: "Crown of the Cosmos",
        source_type: "Raid",
        target_item_level_hint: MidnightSeason.raid_target_hint(),
        target_name: "Starshroud Censer",
        tier: "best"
      },
      %{
        priority: 4,
        reason:
          "Good shoulder route if your armor slots are uneven and you need a clean raid-only upgrade target.",
        slot_keys: ["SHOULDER"],
        slot_label: "Shoulder",
        source_name: "Vaelgor & Ezzorak",
        source_type: "Raid",
        target_item_level_hint: MidnightSeason.raid_target_hint(),
        target_name: "Mantle of the Twin Dawn",
        tier: "strong"
      },
      %{
        priority: 5,
        reason:
          "High-value chest anchor that keeps stat direction reasonable without sending you into full loot-table mode.",
        slot_keys: ["CHEST"],
        slot_label: "Chest",
        source_name: "Midnight Falls",
        source_type: "Raid",
        target_item_level_hint: MidnightSeason.raid_target_hint(),
        target_name: "Midnight Reliquary Vestment",
        tier: "strong"
      }
    ]
  }

  def for_character("Paladin", "Holy", "dungeons"), do: @holy_paladin_dungeons
  def for_character("Paladin", "Holy", "raid"), do: @holy_paladin_raid
  def for_character(_class_name, _spec_name, mode) when mode in ["dungeons", "raid"], do: nil

  def supported_mode?(mode), do: mode in ["dungeons", "raid"]
end
