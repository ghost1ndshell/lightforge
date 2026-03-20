defmodule Lightforge.Wow.GearPlanner do
  @moduledoc false

  alias Lightforge.Wow.GearTarget
  alias Lightforge.Wow.Item

  @holy_paladin_guide_name "Method"
  @holy_paladin_guide_url "https://www.method.gg/guides/holy-paladin/gearing"

  def build(character_class, spec_name, items)
      when character_class == "Paladin" and spec_name == "Holy" do
    build_holy_paladin_plan(items)
  end

  def build(character_class, spec_name, _items)
      when is_binary(character_class) and character_class != "" and is_binary(spec_name) and
             spec_name != "" do
    %{
      guide_name: "Coming soon",
      guide_url: nil,
      note:
        "Midnight season gear targets are not curated yet. Previous expansion suggestions have been removed and this section will stay placeholder-only until the planner is updated for current-season loot.",
      pending?: true,
      targets: []
    }
  end

  def build(_character_class, _spec_name, _items), do: nil

  defp build_holy_paladin_plan(items) do
    %{
      guide_name: @holy_paladin_guide_name,
      guide_url: @holy_paladin_guide_url,
      note:
        "This is a Midnight pre-season Holy Paladin plan based on current 12.0 launch guidance. Blizzard says Midnight Season 1 starts on March 17, 2026, so these targets should be treated as a short-lived bridge until Season 1 loot opens.",
      pending?: false,
      targets:
        [
          %{
            content_type: "Campaign",
            note: "Current cloak baseline in launch-period Holy Paladin gearing.",
            priority: 1,
            slot_keys: ["BACK"],
            slot_label: "Back",
            source: "Main quest / Reshii Wraps progression",
            target_name: "Reshii Wraps"
          },
          %{
            content_type: "Dungeon",
            note: "Strong current pre-season trinket choice from the launch dungeon pool.",
            priority: 2,
            slot_keys: ["TRINKET_1", "TRINKET_2"],
            slot_label: "Trinket",
            source: "The Dawnbreaker",
            target_name: "Empowering Crystal of Anub'ikkaj"
          },
          %{
            content_type: "Dungeon",
            note: "Good all-purpose stat-stick trinket for current launch gearing.",
            priority: 3,
            slot_keys: ["TRINKET_1", "TRINKET_2"],
            slot_label: "Trinket",
            source: "Tazavesh",
            target_name: "So'leah's Secret Technique"
          },
          %{
            content_type: "Dungeon",
            note: "Current pre-season weapon target from the Method launch list.",
            priority: 4,
            slot_keys: ["MAIN_HAND"],
            slot_label: "Weapon",
            source: "Ara-Kara, City of Echoes",
            target_name: "Arachnoid Soulcleaver"
          },
          %{
            content_type: "Dungeon",
            note: "Current pre-season off-hand target paired with dungeon weapon routes.",
            priority: 5,
            slot_keys: ["OFF_HAND"],
            slot_label: "Off-Hand",
            source: "Eco-Dome Al'dani",
            target_name: "Starlit Safeguard"
          },
          %{
            content_type: "Dungeon",
            note: "Good current ring target if your jewelry is lagging behind.",
            priority: 6,
            slot_keys: ["FINGER_1", "FINGER_2"],
            slot_label: "Ring",
            source: "Halls of Atonement",
            target_name: "Signet of the False Accuser"
          }
        ]
        |> Enum.map(&enrich_target(&1, items))
    }
  end

  defp enrich_target(target, items) do
    current_items =
      items
      |> Enum.filter(&(&1.slot_key in target.slot_keys))
      |> Enum.sort_by(&slot_index(&1.slot_key))

    current_label =
      case current_items do
        [] ->
          "No current item tracked"

        matched ->
          matched
          |> Enum.map_join(" / ", fn item ->
            suffix = if is_integer(item.item_level), do: " (#{item.item_level})", else: ""
            item.name <> suffix
          end)
      end

    %GearTarget{
      acquired?: Enum.any?(current_items, &same_item_name?(&1, target.target_name)),
      content_type: target.content_type,
      current_label: current_label,
      current_level: current_level(current_items),
      note: target.note,
      priority: target.priority,
      slot_keys: target.slot_keys,
      slot_label: target.slot_label,
      source: target.source,
      source_url: target[:source_url],
      target_name: target.target_name
    }
  end

  defp current_level(current_items) do
    current_items
    |> Enum.map(& &1.item_level)
    |> Enum.filter(&is_integer/1)
    |> Enum.max(fn -> nil end)
  end

  defp same_item_name?(%Item{name: current_name}, target_name) do
    normalize_name(current_name) == normalize_name(target_name)
  end

  defp normalize_name(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.trim()
  end

  defp slot_index(slot_key) do
    Enum.find_index(
      ["BACK", "FINGER_1", "FINGER_2", "TRINKET_1", "TRINKET_2", "MAIN_HAND", "OFF_HAND"],
      &(&1 == slot_key)
    ) || 999
  end
end
