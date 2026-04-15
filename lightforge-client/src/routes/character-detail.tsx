import { useState } from "react";
import { Link, useMatch } from "@tanstack/react-router";
import {
  AnimatePresence,
  motion,
} from "motion/react";
import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";
import type { GearItem } from "../features/characters/api";
import {
  useCharacter,
  useCharacterGear,
  useCharacterSnapshot,
} from "../features/characters/hooks";

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

  const characterQuery = useCharacter(region, realm, name);
  const snapshotQuery = useCharacterSnapshot(region, realm, name);
  const gearQuery = useCharacterGear(region, realm, name);

  const character = characterQuery.data?.data.character;
  const latestSnapshot = characterQuery.data?.data.latest_snapshot;
  const snapshot = snapshotQuery.data?.data ?? null;
  const items = gearQuery.data?.data.items ?? [];
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
                    {latestSnapshot?.equipped_item_level ?? "?"}
                  </p>
                </article>

                <article className="forge-stage__meta-card">
                  <p className="forge-section-kicker">Last Sync</p>
                  <p className="mt-3 text-sm leading-7 text-[color:var(--text-soft)]">
                    {formatTimestamp(latestSnapshot?.captured_at)}
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

            {(snapshotQuery.isPending || gearQuery.isPending) && (
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
