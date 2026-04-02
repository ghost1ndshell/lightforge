import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";

export function CharactersPage() {
  return (
    <AppShell>
      <div className="py-8">
        <Panel className="p-8">
          <h1 className="text-3xl text-[color:var(--text-ink)]">Characters</h1>
          <p className="mt-3 text-[color:var(--text-soft)]">
            Stored characters
          </p>
        </Panel>
      </div>
    </AppShell>
  );
}
