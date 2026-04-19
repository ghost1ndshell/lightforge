import { AppShell } from "./components/layout/AppShell";
import { Panel } from "./components/ui/Panel";

export default function App() {
  return (
    <AppShell>
      <div className="grid gap-6 py-8">
        <Panel className="p-8">
          <p className="text-xs uppercase tracking-[0.35em] text-[color:var(--text-muted)]">
            Lightforge
          </p>

          <h1 className="mt-4 text-5xl font-semibold tracking-tight text-[color:var(--text-ink)]">
            Arcane forge interface prototype
          </h1>

          <p className="mt-4 max-w-2xl text-base leading-7 text-[color:var(--text-soft)]">
            This is the first styled shell for the React client. We are testing
            the forged parchment panel system, the warm arcane background, and
            the cyan hover behavior before building real pages.
          </p>
        </Panel>

        <div className="grid gap-6 lg:grid-cols-2">
          <Panel className="p-6">
            <h2 className="text-2xl font-semibold text-[color:var(--text-ink)]">
              Character surfaces
            </h2>
            <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
              Character overview, gear cards, and progression panels will live
              on top of this scroll-like foundation.
            </p>
          </Panel>

          <Panel className="p-6">
            <h2 className="text-2xl font-semibold text-[color:var(--text-ink)]">
              Insight surfaces
            </h2>
            <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
              Warcraft Logs and analysis recommendations will be layered into
              ranked, readable cards with clear severity and action guidance.
            </p>
          </Panel>
        </div>
      </div>
    </AppShell>
  );
}
