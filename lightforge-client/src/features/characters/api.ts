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
