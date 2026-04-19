import { useQuery } from "@tanstack/react-query";
import {
  getCharacter,
  getCharacterDetail,
  getCharacters,
  getCharacterGear,
  getCharacterGearing,
  getCharacterSnapshot,
  type GearingMode,
} from "./api";

export function useCharacters() {
  return useQuery({
    queryKey: ["characters"],
    queryFn: getCharacters,
  });
}

export function useCharacter(region: string, realm: string, name: string) {
  return useQuery({
    queryKey: ["character", region, realm, name],
    queryFn: () => getCharacter(region, realm, name),
  });
}

export function useCharacterDetail(region: string, realm: string, name: string) {
  return useQuery({
    queryKey: ["character", region, realm, name, "detail"],
    queryFn: () => getCharacterDetail(region, realm, name),
  });
}

export function useCharacterSnapshot(
  region: string,
  realm: string,
  name: string,
) {
  return useQuery({
    queryKey: ["character", region, realm, name, "snapshot"],
    queryFn: () => getCharacterSnapshot(region, realm, name),
  });
}

export function useCharacterGear(region: string, realm: string, name: string) {
  return useQuery({
    queryKey: ["character", region, realm, name, "gear"],
    queryFn: () => getCharacterGear(region, realm, name),
  });
}

export function useCharacterGearing(
  region: string,
  realm: string,
  name: string,
  mode: GearingMode,
) {
  return useQuery({
    queryKey: ["character", region, realm, name, "gearing", mode],
    queryFn: () => getCharacterGearing(region, realm, name, mode),
  });
}
