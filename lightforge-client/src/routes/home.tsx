import { Link } from "@tanstack/react-router";
import { useState } from "react";
import { AppShell } from "../components/layout/AppShell";
import { Button } from "../components/ui/Button";
import { Panel } from "../components/ui/Panel";
import { useBattleNetStatus } from "../features/auth/hooks";
import { startBattleNetConnect } from "../features/auth/api";

export function HomePage() {
  const statusQuery = useBattleNetStatus();
  const [isConnecting, setIsConnecting] = useState(false);

  async function handleConnect() {
    setIsConnecting(true);

    try {
      const resp = await startBattleNetConnect();

      if (resp.data.authorize_url) {
        window.location.href = resp.data.authorize_url;
        return;
      }
    } finally {
      setIsConnecting(false);
    }
  }

  return (
    <AppShell>
      <div className="grid gap-6 py-8">
        <Panel className="p-8">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <p className="text-xs uppercase tracking-[0.35em] text-[color:var(--text-muted)]">
              Lightforge
            </p>

            <div className="sm:flex sm:justify-end">
              {statusQuery.isPending && (
                <p className="text-sm text-[color:var(--text-muted)]">
                  Checking Battle.net status...
                </p>
              )}

              {statusQuery.isError && (
                <p className="text-sm text-red-700">
                  Could not load Battle.net status.
                </p>
              )}

              {statusQuery.data && (
                <div
                  className="forge-status"
                  data-state={
                    statusQuery.data.data.connected
                      ? "connected"
                      : "disconnected"
                  }
                >
                  <span className="text-sm font-medium">
                    {statusQuery.data.data.connected
                      ? "Battle.net connected"
                      : "Battle.net not connected"}
                  </span>
                </div>
              )}
            </div>
          </div>

          <h1 className="mt-6 text-5xl text-(--text-ink)">
            Gear insight enhancement
          </h1>

          <p className="mt-4 max-w-2xl text-base leading-7 text-(--text-soft)">
            Connect Battle.net, sync characters, inspect gear, and turn
            encounter analysis into clear next actions.
          </p>

          {statusQuery.data && (
            <div className="mt-8 flex flex-wrap gap-3">
              {!statusQuery.data.data.connected && (
                <Button
                  disabled={isConnecting}
                  onClick={handleConnect}
                  className="px-5 py-3"
                >
                  {isConnecting
                    ? "Opening Battle.net..."
                    : "Connect Battle.net"}
                </Button>
              )}

              {statusQuery.data.data.connected && (
                <Link
                  to="/characters"
                  className="forge-button forge-button--secondary px-5 py-3"
                >
                  View characters
                </Link>
              )}
            </div>
          )}
        </Panel>
      </div>
    </AppShell>
  );
}
