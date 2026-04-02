import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";

export function HomePage() {
  return (
    <AppShell>
      <div className="grid gap-6 py-8">
        <Panel className="p-8">
          <p className="text-xs uppercase tracking-[0.35em] text-[color:var(--text-muted)]">
            Lightforge
          </p>

          <h1 className="mt-4 text-5xl text-[color:var(--text-ink)]">
            A forged interface for Azeroth analysis
          </h1>

          <p className="mt-4 max-w-2xl text-base leading-7 text-[color:var(--text-soft)]">
            Connect Battle.net, sync characters, inspect gear, and turn
            encounter analysis into clear next actions.
          </p>
        </Panel>
      </div>
    </AppShell>
  );
}
