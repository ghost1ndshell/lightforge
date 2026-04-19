import { useQuery } from "@tanstack/react-query";
import { getBattleNetStatus } from "./api";

export function useBattleNetStatus() {
  return useQuery({
    queryKey: ["bnet", "status"],
    queryFn: getBattleNetStatus,
  });
}
