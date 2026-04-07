import { Link, useMatch } from "@tanstack/react-router";
import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";
import type { GearItem } from "../features/characters/api";
import {
  useCharacter,
  useCharacterGear,
  useCharacterSnapshot,
} from "../features/characters/hooks";

type JsonMap = Record<string, unknown>;

type StatCard = {
  label: string;
  value: number;
  unit?: string;
};

const slotOrder: Record<string, number> = {
  HEAD: 1,
  NECK: 2,
  SHOULDER: 3,
  BACK: 4,
  CHEST: 5,
  WRIST: 6,
  HANDS: 7,
  WAIST: 8,
  LEGS: 9,
  FEET: 10,
  FINGER_1: 11,
  FINGER_2: 12,
  TRINKET_1: 13,
  TRINKET_2: 14,
  MAIN_HAND: 15,
  OFF_HAND: 16,
  TWOHWEAPON: 17,
};

function asRecord(value: unknown): JsonMap | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonMap)
    : null;
}

function readPath(source: JsonMap | null, path: string[]): unknown {
  return path.reduce<unknown>((current, key) => {
    const record = asRecord(current);
    return record ? record[key] : undefined;
  }, source);
}

function firstNumber(source: JsonMap | null, candidates: string[][]): number | null {
  for (const path of candidates) {
    const value = readPath(source, path);

    if (typeof value === "number" && Number.isFinite(value)) {
      return value;
    }

    if (typeof value === "string") {
      const parsed = Number(value);

      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }

  return null;
}

function formatTimestamp(value: string | null | undefined) {
  if (!value) {
    return "Unknown";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

function buildStatCards(statistics: JsonMap | null): StatCard[] {
  const definitions = [
    {
      label: "Haste",
      unit: "%",
      candidates: [["haste", "rating"], ["haste", "value"], ["haste"]],
    },
    {
      label: "Mastery",
      unit: "%",
      candidates: [["mastery", "rating"], ["mastery", "value"], ["mastery"]],
    },
    {
      label: "Critical Strike",
      unit: "%",
      candidates: [
        ["crit", "rating"],
        ["critical_strike", "rating"],
        ["criticalStrike", "rating"],
        ["crit"],
      ],
    },
    {
      label: "Versatility",
      unit: "%",
      candidates: [["versatility", "rating"], ["versatility", "value"], ["versatility"]],
    },
  ];

  return definitions.reduce<StatCard[]>((cards, definition) => {
    const value = firstNumber(statistics, definition.candidates);

    if (value !== null) {
      cards.push({ label: definition.label, value, unit: definition.unit });
    }

    return cards;
  }, []);
}

function sortGearItems(items: GearItem[]) {
  return [...items].sort((left, right) => {
    const leftOrder = slotOrder[left.slot_key ?? ""] ?? 999;
    const rightOrder = slotOrder[right.slot_key ?? ""] ?? 999;

    if (leftOrder !== rightOrder) {
      return leftOrder - rightOrder;
    }

    return (left.slot_name ?? "").localeCompare(right.slot_name ?? "");
  });
}

function rarityColor(quality: string | null) {
  const normalized = quality?.toLowerCase() ?? "";

  if (normalized.includes("legendary")) {
    return "var(--rarity-legendary)";
  }

  if (normalized.includes("epic") || normalized.includes("mythic")) {
    return "var(--rarity-mythic)";
  }

  if (normalized.includes("rare")) {
    return "var(--rarity-rare)";
  }

  if (normalized.includes("uncommon") || normalized.includes("normal")) {
    return "var(--rarity-normal)";
  }

  return "var(--text-ink)";
}

function rarityBorder(quality: string | null) {
  const normalized = quality?.toLowerCase() ?? "";

  if (normalized.includes("legendary")) {
    return "rgba(231, 163, 58, 0.28)";
  }

  if (normalized.includes("epic") || normalized.includes("mythic")) {
    return "rgba(165, 109, 255, 0.24)";
  }

  if (normalized.includes("rare")) {
    return "rgba(87, 166, 255, 0.24)";
  }

  if (normalized.includes("uncommon") || normalized.includes("normal")) {
    return "rgba(94, 203, 131, 0.24)";
  }

  return "rgba(110, 73, 34, 0.16)";
}

function getTrinkets(items: GearItem[]) {
  return items.filter((item) => {
    const key = (item.slot_key ?? item.slot_name ?? "").toLowerCase();
    return key.includes("trinket");
  });
}

export function CharacterDetailPage() {
  const match = useMatch({ from: "/characters/$region/$realm/$name" });
  const { region, realm, name } = match.params;

  const characterQuery = useCharacter(region, realm, name);
  const snapshotQuery = useCharacterSnapshot(region, realm, name);
  const gearQuery = useCharacterGear(region, realm, name);

  const snapshot = snapshotQuery.data?.data ?? null;
  const sortedGear = sortGearItems(gearQuery.data?.data.items ?? []);
  const statCards = buildStatCards(snapshot?.statistics_json ?? null);
  const trinkets = getTrinkets(sortedGear);

  return (
    <AppShell>
      <div className="grid gap-6 py-8">
        <div className="flex items-center justify-between gap-4">
          <Link
            to="/characters"
            className="forge-button forge-button--secondary px-4 py-2"
          >
            Back to roster
          </Link>
        </div>

        {characterQuery.isPending && (
          <Panel className="p-6">
            <p className="text-sm text-[color:var(--text-muted)]">
              Loading forged profile...
            </p>
          </Panel>
        )}

        {characterQuery.isError && (
          <Panel className="p-6">
            <p className="text-sm text-red-700">
              Could not load this character.
            </p>
          </Panel>
        )}

        {characterQuery.data && (
          <>
            <div className="grid gap-6 xl:grid-cols-[1.25fr_0.85fr]">
              <div className="grid gap-6">
                <Panel className="p-8">
                  <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(18rem,24rem)] lg:items-start">
                    <div className="min-w-0 space-y-6">
                      <div className="min-w-0">
                        <p className="forge-section-kicker">Forged Profile</p>
                        <h1 className="mt-4 truncate text-5xl text-[color:var(--text-ink)]">
                          {characterQuery.data.data.character.name}
                        </h1>
                        <p className="mt-3 text-base text-[color:var(--text-soft)]">
                          {characterQuery.data.data.character.realm} ·{" "}
                          {characterQuery.data.data.character.region.toUpperCase()}
                        </p>

                        <div className="mt-5 flex flex-wrap gap-2">
                          <span className="forge-data-chip">
                            {characterQuery.data.data.character.spec_name ?? "Unknown spec"}
                          </span>
                          <span className="forge-data-chip">
                            {characterQuery.data.data.character.class_name ?? "Unknown class"}
                          </span>
                          <span className="forge-data-chip">
                            Level {characterQuery.data.data.character.level ?? "?"}
                          </span>
                        </div>
                      </div>

                      <div className="forge-quiet-panel bg-[rgba(255,247,236,0.76)]">
                        <div className="flex items-center justify-between gap-3">
                          <p className="forge-section-kicker">Stat Forge</p>
                          {snapshotQuery.isPending && (
                            <span className="text-xs uppercase tracking-[0.18em] text-[color:var(--text-muted)]">
                              Reading
                            </span>
                          )}
                        </div>

                        <div className="mt-4 grid gap-3 sm:grid-cols-2">
                          {(statCards.length > 0
                            ? statCards
                            : [
                                { label: "Stats", value: 0, unit: "", placeholder: "Awaiting mapping" },
                                { label: "Goals", value: 0, unit: "", placeholder: "Planner needed" },
                                { label: "Delta", value: 0, unit: "", placeholder: "Spec rules pending" },
                                { label: "Focus", value: 0, unit: "", placeholder: "No stat model yet" },
                              ]
                          ).map((stat) => (
                            <div
                              key={stat.label}
                              className="rounded-2xl border border-[rgba(110,73,34,0.14)] bg-[rgba(255,250,243,0.8)] px-4 py-4 shadow-[inset_0_1px_0_rgba(255,252,246,0.54)]"
                            >
                              <p className="text-[11px] uppercase tracking-[0.22em] text-[color:var(--text-muted)]">
                                {stat.label}
                              </p>
                              {"placeholder" in stat ? (
                                <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                                  {stat.placeholder}
                                </p>
                              ) : (
                                <>
                                  <p className="mt-3 text-2xl text-[color:var(--text-ink)]">
                                    {stat.value.toLocaleString()}
                                    {stat.unit && (
                                      <span className="ml-1 text-base text-[color:var(--text-soft)]">
                                        {stat.unit}
                                      </span>
                                    )}
                                  </p>
                                  <div className="mt-3 h-1.5 rounded-full bg-[rgba(125,93,64,0.12)]">
                                    <div
                                      className="h-full rounded-full bg-[linear-gradient(90deg,rgba(179,112,44,0.88),rgba(69,223,242,0.58))]"
                                      style={{ width: `${Math.min(stat.value, 100)}%` }}
                                    />
                                  </div>
                                </>
                              )}
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>

                    <div className="grid gap-3">
                      <div className="forge-metric-tile">
                        <p className="forge-section-kicker">Item Level</p>
                        <p className="mt-3 text-4xl text-[color:var(--text-ink)]">
                          {characterQuery.data.data.latest_snapshot?.equipped_item_level ?? "?"}
                        </p>
                        <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                          Current equipped benchmark
                        </p>
                      </div>

                      <div className="forge-metric-tile">
                        <p className="forge-section-kicker">Gear Stored</p>
                        <p className="mt-3 text-3xl text-[color:var(--text-ink)]">
                          {characterQuery.data.data.latest_snapshot?.gear_item_count ?? 0}
                        </p>
                        <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                          Items captured in the latest snapshot
                        </p>
                      </div>

                      <div className="forge-metric-tile">
                        <p className="forge-section-kicker">Last Sync</p>
                        <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                          {formatTimestamp(characterQuery.data.data.latest_snapshot?.captured_at)}
                        </p>
                        <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                          Use this to judge how fresh the profile is
                        </p>
                      </div>
                    </div>
                  </div>
                </Panel>

                <Panel className="p-6">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
                    <div className="forge-section-heading">
                      <p className="forge-section-kicker">Gear Anvil</p>
                      <h2 className="text-3xl text-[color:var(--text-ink)]">
                        Equipped loadout
                      </h2>
                    </div>

                    {gearQuery.isPending && (
                      <p className="text-sm text-[color:var(--text-muted)]">
                        Reading gear...
                      </p>
                    )}
                  </div>

                  {gearQuery.isError && (
                    <p className="mt-5 text-sm text-red-700">
                      Equipped gear could not be loaded.
                    </p>
                  )}

                  {!gearQuery.isError && sortedGear.length === 0 && (
                    <div className="forge-quiet-panel mt-5">
                      <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                        No gear snapshot is stored yet for this character.
                      </p>
                    </div>
                  )}

                  {sortedGear.length > 0 && (
                    <div className="mt-5 grid gap-3 sm:grid-cols-2">
                      {sortedGear.map((item) => (
                        <div
                          key={`${item.slot_key}-${item.blizzard_item_id ?? item.item_name}`}
                          className="forge-quiet-panel transition-transform duration-200 hover:-translate-y-1"
                          style={{ borderColor: rarityBorder(item.quality) }}
                        >
                          <div className="flex items-start gap-3">
                            {item.icon_url ? (
                              <img
                                alt={item.item_name ?? item.slot_name ?? "Item icon"}
                                className="h-12 w-12 rounded-2xl border border-[rgba(110,73,34,0.14)] object-cover"
                                src={item.icon_url}
                              />
                            ) : (
                              <div className="flex h-12 w-12 items-center justify-center rounded-2xl border border-[rgba(110,73,34,0.14)] bg-[rgba(234,220,198,0.66)] text-xs text-[color:var(--text-muted)]">
                                --
                              </div>
                            )}

                            <div className="min-w-0">
                              <p className="text-[11px] uppercase tracking-[0.22em] text-[color:var(--text-muted)]">
                                {item.slot_name ?? item.slot_key ?? "Slot"}
                              </p>
                              <h3
                                className="mt-1 line-clamp-2 text-lg"
                                style={{ color: rarityColor(item.quality) }}
                              >
                                {item.item_name ?? "Unknown item"}
                              </h3>
                            </div>
                          </div>

                          <div className="mt-4 flex flex-wrap gap-2">
                            <span className="forge-data-chip">iLvl {item.item_level ?? "?"}</span>
                            {item.inventory_type && (
                              <span className="forge-data-chip">{item.inventory_type}</span>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </Panel>
              </div>

              <div className="grid gap-6">
                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Trinket Chamber</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Current relics
                    </h2>
                  </div>

                  {trinkets.length > 0 ? (
                    <div className="mt-5 grid gap-3">
                      {trinkets.map((trinket) => (
                        <div
                          key={`${trinket.slot_key}-${trinket.blizzard_item_id ?? trinket.item_name}`}
                          className="forge-quiet-panel"
                          style={{ borderColor: rarityBorder(trinket.quality) }}
                        >
                          <p className="forge-section-kicker">
                            {trinket.slot_name ?? trinket.slot_key ?? "Trinket"}
                          </p>
                          <h3
                            className="mt-2 text-2xl"
                            style={{ color: rarityColor(trinket.quality) }}
                          >
                            {trinket.item_name ?? "Unknown trinket"}
                          </h3>
                          <p className="mt-3 text-sm text-[color:var(--text-soft)]">
                            iLvl {trinket.item_level ?? "?"}
                          </p>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="forge-quiet-panel mt-5">
                      <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                        No trinkets were found in the stored gear snapshot.
                      </p>
                    </div>
                  )}

                  <div className="forge-quiet-panel mt-4">
                    <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                      S-tier trinkets and equip-impact should appear here once the
                      recommendation layer is ready.
                    </p>
                  </div>
                </Panel>

                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Encounter Intelligence</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Highest-impact signals
                    </h2>
                  </div>

                  <div className="mt-5 grid gap-3">
                    <div className="forge-quiet-panel">
                      <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                        Warcraft Logs and WoWAnalyzer output should be filtered here
                        into top findings, not long report text.
                      </p>
                    </div>

                    <div className="forge-quiet-panel border-[rgba(69,223,242,0.22)] bg-[rgba(245,252,253,0.56)]">
                      <p className="forge-section-kicker">Reserved slot</p>
                      <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                        This space is for top 3 encounter issues, one-line
                        recommendations, and compact impact indicators.
                      </p>
                    </div>
                  </div>
                </Panel>
              </div>
            </div>

          </>
        )}
      </div>
    </AppShell>
  );
}
