import { useQuery } from "@tanstack/react-query";
import {
  getCharacter,
  getCharacters,
  getCharacterGear,
  getCharacterSnapshot,
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
