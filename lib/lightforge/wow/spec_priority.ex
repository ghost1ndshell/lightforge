defmodule Lightforge.Wow.SpecPriority do
  @moduledoc false

  @reviewed_on ~D[2026-03-09]

  @priorities %{
    {"Demon Hunter", "Havoc"} => %{
      mode: "General PvE",
      note:
        "Agility and item level still win most comparisons. For secondary tuning, lean Crit first, then Mastery, then Haste.",
      priorities: [
        %{key: :crit, label: "Critical Strike", target: "Keep this highest among secondaries"},
        %{key: :mastery, label: "Mastery", target: "Strong supporting stat"},
        %{key: :haste, label: "Haste", target: "Useful once Crit and Mastery are healthy"}
      ],
      source_name: "Icy Veins",
      source_url: "https://www.icy-veins.com/wow/havoc-demon-hunter-pve-dps-stat-priority"
    },
    {"Paladin", "Retribution"} => %{
      mode: "General PvE",
      note:
        "Strength and item level remain the first filter. For secondaries, keep Mastery and Haste ahead of the rest.",
      priorities: [
        %{key: :mastery, label: "Mastery", target: "Primary secondary focus"},
        %{key: :haste, label: "Haste", target: "Keep close behind Mastery"},
        %{key: :crit, label: "Critical Strike", target: "Third priority after Mastery and Haste"}
      ],
      source_name: "Icy Veins",
      source_url: "https://www.icy-veins.com/wow/retribution-paladin-pve-dps-stat-priority"
    },
    {"Paladin", "Protection"} => %{
      mode: "General PvE",
      note:
        "Haste is consistently first. Templar leans Mastery second, while Lightsmith can push Crit ahead, so treat the second and third slots as close.",
      priorities: [
        %{key: :haste, label: "Haste", target: "Primary defensive and rotational focus"},
        %{key: :mastery, label: "Mastery", target: "Strong default second stat for Templar"},
        %{key: :crit, label: "Critical Strike", target: "Competitive with Mastery on Lightsmith"}
      ],
      source_name: "Icy Veins",
      source_url: "https://www.icy-veins.com/wow/protection-paladin-pve-tank-stat-priority"
    },
    {"Paladin", "Holy"} => %{
      mode: "Mythic+",
      note:
        "For high-end Mythic+, Haste stays first, Versatility gains value for damage and survival, and Critical Strike edges out Mastery.",
      priorities: [
        %{key: :haste, label: "Haste", target: "Primary throughput and flow stat"},
        %{key: :versatility, label: "Versatility", target: "High-value dungeon support stat"},
        %{key: :crit, label: "Critical Strike", target: "Preferred over Mastery in Mythic+"}
      ],
      source_name: "Icy Veins",
      source_url: "https://www.icy-veins.com/wow/holy-paladin-pve-healing-stat-priority"
    }
  }

  def for_character(class_name, spec_name)
      when is_binary(class_name) and class_name != "" and is_binary(spec_name) and spec_name != "" do
    case Map.get(@priorities, {class_name, spec_name}) do
      nil ->
        nil

      config ->
        %{
          mode: config.mode,
          note: config.note,
          reviewed_on: @reviewed_on,
          priorities:
            config.priorities
            |> Enum.with_index(1)
            |> Enum.map(fn {priority, index} -> Map.put(priority, :rank, index) end),
          source_name: config.source_name,
          source_url: config.source_url
        }
    end
  end

  def for_character(_class_name, _spec_name), do: nil
end
