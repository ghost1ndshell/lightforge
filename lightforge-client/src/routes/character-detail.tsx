import { useState } from "react";
import { Link, useMatch } from "@tanstack/react-router";
import {
  AnimatePresence,
  motion,
} from "motion/react";
import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";
import type { GearItem } from "../features/characters/api";
import { useCharacterDetail } from "../features/characters/hooks";

type JsonMap = Record<string, unknown>;

type StageSlot = {
  aliases?: string[];
  key: string;
  label: string;
};

const stageSlots: StageSlot[] = [
  { key: "HEAD", label: "Head" },
  { key: "NECK", label: "Neck" },
  { key: "SHOULDER", label: "Shoulder" },
  { key: "BACK", label: "Back" },
  { key: "CHEST", label: "Chest" },
  { key: "WRIST", label: "Wrist" },
  { key: "HANDS", label: "Hands" },
  { key: "WAIST", label: "Waist" },
  { key: "LEGS", label: "Legs" },
  { key: "FEET", label: "Feet" },
  { key: "FINGER_1", label: "Ring I" },
  { key: "FINGER_2", label: "Ring II" },
  { key: "TRINKET_1", label: "Trinket I" },
  { key: "TRINKET_2", label: "Trinket II" },
  { aliases: ["TWOHWEAPON"], key: "MAIN_HAND", label: "Main Hand" },
  { key: "OFF_HAND", label: "Off-Hand" },
];

const slotTransition = {
  type: "spring" as const,
  stiffness: 320,
  damping: 24,
  mass: 0.7,
};

const previewVariants = {
  enter: { opacity: 1, scale: 1, y: 0 },
  exit: { opacity: 0, scale: 0.97, y: 10 },
  initial: { opacity: 0, scale: 0.96, y: 12 },
};

function asRecord(value: unknown): JsonMap | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonMap)
    : null;
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
    return "rgba(231, 163, 58, 0.34)";
  }

  if (normalized.includes("epic") || normalized.includes("mythic")) {
    return "rgba(165, 109, 255, 0.28)";
  }

  if (normalized.includes("rare")) {
    return "rgba(87, 166, 255, 0.28)";
  }

  if (normalized.includes("uncommon") || normalized.includes("normal")) {
    return "rgba(94, 203, 131, 0.28)";
  }

  return "rgba(110, 73, 34, 0.16)";
}

function mediaAssetUrl(mediaJson: JsonMap | null, keys: string[]) {
  const assets = asRecord(mediaJson)?.assets;

  if (!Array.isArray(assets)) {
    return null;
  }

  for (const key of keys) {
    const asset = assets.find((entry) => {
      const record = asRecord(entry);
      return record?.key === key;
    });

    const value = asRecord(asset)?.value;

    if (typeof value === "string" && value !== "") {
      return value;
    }
  }

  return null;
}

function providerLabel(provider: string | null | undefined) {
  if (provider === "wowanalyzer") {
    return "WoWAnalyzer";
  }

  return provider ?? "Unknown provider";
}

function severityTone(severity: string | null | undefined) {
  if (severity === "high") {
    return "border-[rgba(191,67,56,0.22)] bg-[rgba(255,242,239,0.78)] text-[#8f3d32]";
  }

  if (severity === "medium") {
    return "border-[rgba(186,126,50,0.22)] bg-[rgba(255,248,236,0.82)] text-[#8b5f2f]";
  }

  return "border-[rgba(92,78,66,0.16)] bg-[rgba(255,250,243,0.7)] text-[color:var(--text-soft)]";
}

function findItemForSlot(items: GearItem[], slot: StageSlot) {
  const validKeys = [slot.key, ...(slot.aliases ?? [])];

  return items.find((item) => {
    if (!item.slot_key) {
      return false;
    }

    return validKeys.includes(item.slot_key);
  });
}

function renderSlotLabel(slot: StageSlot) {
  return slot.label;
}

function renderSlot(
  slot: StageSlot,
  items: GearItem[],
  activeSlotKey: string | null,
  setActiveSlotKey: (key: string | null) => void,
  index: number,
) {
  const item = findItemForSlot(items, slot);
  const isActive = activeSlotKey === slot.key;

  return (
    <motion.button
      key={slot.key}
      type="button"
      initial={{ opacity: 0, x: 14 }}
      animate={{
        opacity: 1,
        scale: isActive ? 1.02 : 1,
        x: isActive ? -4 : 0,
      }}
      transition={{
        ...slotTransition,
        delay: 0.2 + index * 0.025,
      }}
      whileHover={{ rotateX: -2, scale: 1.025, x: -5 }}
      whileTap={{ scale: 0.99 }}
      className={[
        "forge-stage__slot-row",
        isActive && "forge-stage__slot-row--active",
        !item && "forge-stage__slot-row--empty",
      ]
        .filter(Boolean)
        .join(" ")}
      onBlur={() => setActiveSlotKey(null)}
      onFocus={() => setActiveSlotKey(slot.key)}
      onMouseEnter={() => setActiveSlotKey(slot.key)}
      style={{
        borderColor: isActive
          ? rarityBorder(item?.quality ?? null)
          : undefined,
      }}
    >
      <span
        className={[
          "forge-stage__slot-icon",
          item ? "forge-stage__slot-icon--equipped" : "forge-stage__slot-icon--empty",
        ].join(" ")}
        aria-hidden="true"
      >
        <span className="forge-stage__slot-dot" />
      </span>
      <span className="forge-stage__slot-slug">{renderSlotLabel(slot)}</span>
      <motion.span
        className="forge-stage__slot-sheen"
        aria-hidden="true"
        animate={{
          opacity: isActive ? 1 : 0,
          x: isActive ? 0 : -18,
        }}
        transition={slotTransition}
      />
    </motion.button>
  );
}

export function CharacterDetailPage() {
  const match = useMatch({ from: "/characters/$region/$realm/$name" });
  const { region, realm, name } = match.params;

  const detailQuery = useCharacterDetail(region, realm, name);
  const detail = detailQuery.data?.data;
  const character = detail?.character;
  const snapshot = detail?.snapshot ?? null;
  const items = detail?.items ?? [];
  const analysis = detail?.analysis ?? null;
  const gearing = detail?.gearing;
  const renderUrl = mediaAssetUrl(snapshot?.media_json ?? null, [
    "main-raw",
    "main",
    "avatar",
  ]);
  const [activeSlotKey, setActiveSlotKey] = useState<string | null>(null);
  const primaryRailSlots = stageSlots.slice(0, 8);
  const secondaryRailSlots = stageSlots.slice(8);
  const previewSlot =
    stageSlots.find((slot) => slot.key === activeSlotKey) ?? null;
  const previewItem = previewSlot ? findItemForSlot(items, previewSlot) : null;

  return (
    <AppShell>
      <div className="grid gap-6 py-8">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <Link
            to="/characters"
            className="forge-button forge-button--secondary px-4 py-2"
          >
            Back to roster
          </Link>
        </div>

        {detailQuery.isPending && (
          <Panel className="p-6">
            <p className="text-sm text-[color:var(--text-muted)]">
              Loading forged profile...
            </p>
          </Panel>
        )}

        {detailQuery.isError && (
          <Panel className="p-6">
            <p className="text-sm text-red-700">
              Could not load this character.
            </p>
          </Panel>
        )}

        {character && (
          <Panel className="forge-stage-page p-0">
            <section className="forge-stage__header">
              <div className="forge-stage__brief">
                <p className="forge-section-kicker">Character Briefing</p>
                <div className="forge-stage__title-row">
                  <h1 className="text-5xl text-[color:var(--text-ink)] sm:text-6xl">
                    {character.name}
                  </h1>

                  <div className="forge-stage__pills">
                    <span className="forge-data-chip">
                      {character.spec_name ?? "Unknown spec"}
                    </span>
                    <span className="forge-data-chip">
                      {character.class_name ?? "Unknown class"}
                    </span>
                    <span className="forge-data-chip">
                      Level {character.level ?? "?"}
                    </span>
                    <span className="forge-data-chip">
                      {character.realm} · {character.region.toUpperCase()}
                    </span>
                  </div>
                </div>
              </div>

              <div className="forge-stage__meta">
                <article className="forge-stage__meta-card">
                  <p className="forge-section-kicker">Snapshot</p>
                  <p className="mt-3 text-4xl text-[color:var(--text-ink)]">
                    {snapshot?.equipped_item_level ?? "?"}
                  </p>
                </article>

                <article className="forge-stage__meta-card">
                  <p className="forge-section-kicker">Last Sync</p>
                  <p className="mt-3 text-sm leading-7 text-[color:var(--text-soft)]">
                    {formatTimestamp(snapshot?.captured_at)}
                  </p>
                  <a
                    href="/character"
                    className="mt-4 inline-flex forge-button forge-button--secondary px-4 py-2 text-sm"
                  >
                    Sync latest snapshot
                  </a>
                </article>
              </div>
            </section>

            <motion.section
              className={[
                "forge-stage__scene",
                previewSlot && "forge-stage__scene--active",
              ]
                .filter(Boolean)
                .join(" ")}
              initial={{ opacity: 0, y: 18 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.55, ease: "easeOut" }}
            >
              <motion.div className="forge-stage__render-wrap">
                <motion.div
                  className="forge-stage__render-shell"
                  initial={{ opacity: 0, scale: 0.94, y: 20 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  transition={{ duration: 0.65, ease: "easeOut", delay: 0.12 }}
                >
                  {renderUrl ? (
                    <img
                      alt={`${character.name} character render`}
                      className="forge-stage__render"
                      src={renderUrl}
                    />
                  ) : (
                    <motion.div
                      className="forge-stage__render-fallback"
                      initial={{ opacity: 0, scale: 0.98 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ duration: 0.45, ease: "easeOut" }}
                    >
                      <p className="forge-section-kicker">Render pending</p>
                      <p className="mt-3 text-xl text-[color:var(--text-ink)]">
                        Character media is not available in the latest snapshot.
                      </p>
                    </motion.div>
                  )}
                </motion.div>
              </motion.div>

              <motion.aside
                className="forge-stage__rail"
                initial={{ opacity: 0, x: 24 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, ease: "easeOut", delay: 0.18 }}
                onMouseLeave={() => setActiveSlotKey(null)}
              >
                <AnimatePresence>
                  {previewSlot && (
                    <motion.article
                      key={previewSlot.key}
                      className="forge-stage__preview"
                      initial="initial"
                      animate="enter"
                      exit="exit"
                      variants={previewVariants}
                      transition={slotTransition}
                      style={{
                        borderColor: rarityBorder(previewItem?.quality ?? null),
                      }}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <p className="forge-section-kicker">Slot Preview</p>
                          <h2 className="mt-2 text-2xl text-[color:var(--text-ink)]">
                            {previewSlot.label}
                          </h2>
                        </div>

                        <span
                          className={[
                            "forge-stage__slot-icon",
                            previewItem
                              ? "forge-stage__slot-icon--equipped"
                              : "forge-stage__slot-icon--empty",
                          ].join(" ")}
                          aria-hidden="true"
                        >
                          <span className="forge-stage__slot-dot" />
                        </span>
                      </div>

                      {previewItem ? (
                        <div className="mt-4 grid gap-3">
                          <div>
                            <p
                              className="text-lg leading-7"
                              style={{
                                color: rarityColor(previewItem.quality ?? null),
                              }}
                            >
                              {previewItem.item_name}
                            </p>
                          </div>

                          <div className="flex flex-wrap gap-2">
                            <span className="forge-data-chip">
                              iLvl {previewItem.item_level ?? "--"}
                            </span>
                            {previewItem.inventory_type && (
                              <span className="forge-data-chip">
                                {previewItem.inventory_type}
                              </span>
                            )}
                            {previewItem.quality && (
                              <span className="forge-data-chip">
                                {previewItem.quality}
                              </span>
                            )}
                          </div>
                        </div>
                      ) : (
                        <p className="mt-4 text-sm leading-7 text-[color:var(--text-soft)]">
                          No item equipped in this slot.
                        </p>
                      )}
                    </motion.article>
                  )}
                </AnimatePresence>

                <div
                  className={[
                    "forge-stage__slot-columns",
                    previewSlot && "forge-stage__slot-columns--with-preview",
                  ]
                    .filter(Boolean)
                    .join(" ")}
                >
                  <div className="forge-stage__slot-panel">
                    {primaryRailSlots.map((slot, index) =>
                      renderSlot(slot, items, activeSlotKey, setActiveSlotKey, index),
                    )}
                  </div>

                  <div className="forge-stage__slot-panel">
                    {secondaryRailSlots.map((slot, index) =>
                      renderSlot(
                        slot,
                        items,
                        activeSlotKey,
                        setActiveSlotKey,
                        primaryRailSlots.length + index,
                      ),
                    )}
                  </div>
                </div>
              </motion.aside>
            </motion.section>

            <div className="grid gap-6 px-8 pb-8 xl:grid-cols-[1.15fr_0.85fr]">
              <Panel className="p-6">
                <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Encounter Intelligence</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Selected combat signals
                    </h2>
                  </div>

                  {analysis && (
                    <div className="flex flex-wrap gap-2">
                      <span className="forge-data-chip">
                        {providerLabel(analysis.provider)}
                      </span>
                      {typeof analysis.score === "number" && (
                        <span className="forge-data-chip">
                          Score {analysis.score.toFixed(1)}
                        </span>
                      )}
                    </div>
                  )}
                </div>

                {analysis ? (
                  <div className="mt-5 grid gap-4">
                    <div className="forge-quiet-panel border-[rgba(69,223,242,0.22)] bg-[rgba(245,252,253,0.56)]">
                      <div className="flex flex-wrap items-start justify-between gap-3">
                        <div>
                          <p className="forge-section-kicker">Latest Run</p>
                          <h3 className="mt-2 text-2xl text-[color:var(--text-ink)]">
                            {analysis.fight.encounter_name ?? "Encounter unavailable"}
                          </h3>
                          <p className="mt-2 text-sm leading-6 text-[color:var(--text-soft)]">
                            {typeof analysis.summary_json?.headline === "string"
                              ? analysis.summary_json.headline
                              : "The latest imported run is available below as a compact action list."}
                          </p>
                        </div>

                        <div className="flex flex-wrap gap-2">
                          {analysis.fight.kill && (
                            <span className="forge-data-chip">Kill</span>
                          )}
                          {analysis.fight.report_code && (
                            <span className="forge-data-chip">
                              Report {analysis.fight.report_code}
                            </span>
                          )}
                          <span className="forge-data-chip">
                            {formatTimestamp(analysis.started_at)}
                          </span>
                        </div>
                      </div>
                    </div>

                    {analysis.insights.slice(0, 3).map((insight) => (
                      <article
                        key={insight.id}
                        className="rounded-[1.45rem] border border-[rgba(110,73,34,0.14)] bg-[rgba(255,250,243,0.78)] p-5 shadow-[inset_0_1px_0_rgba(255,252,246,0.56)]"
                      >
                        <div className="flex flex-wrap items-start justify-between gap-3">
                          <div className="min-w-0">
                            <p className="forge-section-kicker">
                              {insight.category ?? "Insight"}
                            </p>
                            <h3 className="mt-2 text-2xl text-[color:var(--text-ink)]">
                              {insight.title}
                            </h3>
                          </div>

                          <div className="flex flex-wrap items-center gap-2">
                            <span
                              className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] ${severityTone(insight.severity)}`}
                            >
                              {insight.severity ?? "note"}
                            </span>
                            {typeof insight.impact_score === "number" && (
                              <span className="forge-data-chip">
                                Impact {insight.impact_score.toFixed(1)}
                              </span>
                            )}
                          </div>
                        </div>

                        {insight.summary && (
                          <p className="mt-4 text-sm leading-6 text-[color:var(--text-soft)]">
                            {insight.summary}
                          </p>
                        )}

                        {insight.recommendation && (
                          <div className="forge-quiet-panel mt-4">
                            <p className="forge-section-kicker">Next adjustment</p>
                            <p className="mt-2 text-sm leading-6 text-[color:var(--text-soft)]">
                              {insight.recommendation}
                            </p>
                          </div>
                        )}
                      </article>
                    ))}
                  </div>
                ) : (
                  <div className="forge-quiet-panel mt-5">
                    <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                      No imported WoWAnalyzer-style run is attached to this character yet.
                      Import a Warcraft Logs analysis run to populate this surface.
                    </p>
                  </div>
                )}
              </Panel>

              <div className="grid gap-6">
                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Forge Direction</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Narrow upgrade route
                    </h2>
                  </div>

                  {gearing && (
                    <>
                      <div className="forge-quiet-panel mt-5 border-[rgba(69,223,242,0.22)] bg-[rgba(245,252,253,0.56)]">
                        <p className="forge-section-kicker">{gearing.meta.source_name}</p>
                        <h3 className="mt-2 text-2xl text-[color:var(--text-ink)]">
                          {gearing.summary.headline}
                        </h3>
                        <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                          {gearing.summary.subheadline}
                        </p>
                      </div>

                      <div className="mt-4 grid gap-3">
                        {gearing.top_targets.slice(0, 3).map((target) => (
                          <article
                            key={`${target.slot}-${target.target_name}`}
                            className="rounded-[1.35rem] border border-[rgba(110,73,34,0.14)] bg-[rgba(255,250,243,0.78)] p-4 shadow-[inset_0_1px_0_rgba(255,252,246,0.56)]"
                          >
                            <div className="flex items-start justify-between gap-3">
                              <div>
                                <p className="forge-section-kicker">{target.slot}</p>
                                <h3 className="mt-2 text-lg text-[color:var(--text-ink)]">
                                  {target.target_name}
                                </h3>
                              </div>

                              <span className="forge-data-chip">
                                {target.source_type}
                              </span>
                            </div>

                            <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                              {target.reason}
                            </p>
                          </article>
                        ))}
                      </div>
                    </>
                  )}
                </Panel>

                {gearing?.stat_direction && (
                  <Panel className="p-6">
                    <div className="forge-section-heading">
                      <p className="forge-section-kicker">Stat Focus</p>
                      <h2 className="text-3xl text-[color:var(--text-ink)]">
                        Current pressure points
                      </h2>
                    </div>

                    <div className="mt-5 grid gap-3">
                      {gearing.stat_direction.focus.map((goal) => (
                        <div key={goal.label} className="forge-quiet-panel">
                          <div className="flex items-start justify-between gap-3">
                            <div>
                              <p className="forge-section-kicker">{goal.label}</p>
                              <p className="mt-2 text-lg text-[color:var(--text-ink)]">
                                {goal.current_display}
                              </p>
                            </div>

                            <span className="forge-data-chip">
                              Target {goal.target_display}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </Panel>
                )}
              </div>
            </div>

            {detailQuery.isPending && (
              <div className="px-8 pb-8">
                <div className="forge-quiet-panel">
                  <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                    Refreshing stage data...
                  </p>
                </div>
              </div>
            )}
          </Panel>
        )}
      </div>
    </AppShell>
  );
}
