import { api } from "../../lib/api/client";

export type BattleNetStatusResponse = {
  data: {
    connected: boolean;
    config_ready?: boolean;
    provider: string;
  };
};

export type BattleNetStartResponse = {
  data: {
    authorize_url: string | null;
    provider: string;
  };
};

export function getBattleNetStatus() {
  return api<BattleNetStatusResponse>("/api/v1/me/bnet/status");
}

export function startBattleNetConnect() {
  return api<BattleNetStartResponse>("/api/v1/bnet/connect/start", {
    method: "POST",
  });
}
