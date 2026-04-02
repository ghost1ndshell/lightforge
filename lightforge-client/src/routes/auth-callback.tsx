import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";

export function AuthCallbackPage() {
  return (
    <AppShell>
      <div className="py-8">
        <Panel className="p-8">
          <h1 className="text-3xl text-[color:var(--text-ink)]">
            Battle.net callback
          </h1>
          <p className="mt-3 text-[color:var(--text-soft)]">
            This page will handle the backend redirect result.
          </p>
        </Panel>
      </div>
    </AppShell>
  );
}
