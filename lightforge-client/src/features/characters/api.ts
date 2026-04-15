import { api } from "../../lib/api/client";

type JsonMap = Record<string, unknown>;

export type CharacterListItem = {
  id: number;
  region: string;
  realm: string;
  realm_slug: string;
  name: string;
  class_name: string | null;
  spec_name: string | null;
  level: number | null;
};

export type CharactersIndexResponse = {
  data: CharacterListItem[];
};

export type CharacterShowResponse = {
  data: {
    character: CharacterListItem;
    latest_snapshot: {
      id: number;
      equipped_item_level: number | null;
      captured_at: string;
      gear_item_count: number;
    } | null;
  };
};

export type CharacterSnapshotResponse = {
  data: {
    id: number;
    captured_at: string;
    equipped_item_level: number | null;
    statistics_json: JsonMap | null;
    mythic_json: JsonMap | null;
    profile_json: JsonMap | null;
    media_json: JsonMap | null;
    achievements_json: JsonMap | null;
  };
};

export type GearItem = {
  blizzard_item_id: number | null;
  icon_url: string | null;
  inventory_type: string | null;
  item_level: number | null;
  item_name: string | null;
  quality: string | null;
  slot_key: string | null;
  slot_name: string | null;
};

export type CharacterGearResponse = {
  data: {
    character: CharacterListItem;
    snapshot_id: number;
    items: GearItem[];
  };
};

export type GearingMode = "dungeons" | "raid";

export type GearingTarget = {
  current_item_level: number | null;
  current_item_name: string;
  priority: number;
  reason: string;
  slot: string;
  source_name: string;
  source_type: string;
  status: string;
  target_item_level_hint: number | null;
  target_name: string;
  tier: string;
};

export type GearingPrioritySlot = {
  current_item_level: number | null;
  reason: string;
  slot: string;
  urgency: string;
};

export type GearingStatFocus = {
  current_display: string;
  label: string;
  progress: number | null;
  target_display: string;
};

export type GearingStatLine = {
  display: string;
  label: string;
};

export type CharacterGearingResponse = {
  data: {
    character: {
      class_name: string | null;
      level: number | null;
      name: string;
      region: string;
      realm: string;
      spec_name: string | null;
    };
    current_trinkets: Array<{
      item_level: number | null;
      item_name: string | null;
      slot: string | null;
    }>;
    meta: {
      note: string;
      reviewed_on: string | null;
      season: string;
      source_name: string;
    };
    mode: GearingMode;
    pending: boolean;
    priority_slots: GearingPrioritySlot[];
    snapshot: {
      captured_at: string;
      equipped_item_level: number | null;
      id: number;
    };
    stat_direction: {
      current: GearingStatLine[];
      focus: GearingStatFocus[];
      mode: string;
      note: string;
      reviewed_on: string;
      source_name: string;
      source_url?: string | null;
    } | null;
    summary: {
      headline: string;
      subheadline: string;
    };
    top_targets: GearingTarget[];
    weekly_route: Array<{
      label: string;
      reason: string;
      source_name: string;
      source_type: string;
    }>;
  };
};

export function getCharacters() {
  return api<CharactersIndexResponse>("/api/v1/characters");
}

export function getCharacter(region: string, realm: string, name: string) {
  return api<CharacterShowResponse>(
    `/api/v1/characters/${region}/${realm}/${name}`,
  );
}

export function getCharacterSnapshot(
  region: string,
  realm: string,
  name: string,
) {
  return api<CharacterSnapshotResponse>(
    `/api/v1/characters/${region}/${realm}/${name}/snapshots/latest`,
  );
}

export function getCharacterGear(region: string, realm: string, name: string) {
  return api<CharacterGearResponse>(
    `/api/v1/characters/${region}/${realm}/${name}/gear`,
  );
}

export function getCharacterGearing(
  region: string,
  realm: string,
  name: string,
  mode: GearingMode,
) {
  return api<CharacterGearingResponse>(
    `/api/v1/characters/${region}/${realm}/${name}/gearing?mode=${mode}`,
  );
}
