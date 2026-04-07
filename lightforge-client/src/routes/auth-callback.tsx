import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";
import { Link } from "@tanstack/react-router";

export function AuthCallbackPage() {
  const params = new URLSearchParams(window.location.search);
  const status = params.get("status");
  const provider = params.get("provider");
  const message = params.get("message");

  const isSuccess = status === "success";
  const isError = status === "error";

  let title = "No callbacks found";
  let description = message ?? "Pending Battle.net authentication";
  let actionLabel = "Return Home";
  let actionTo = "/";

  if (isSuccess) {
    title = "Battle.net connected";
    description = message ?? "Battle.net session is now connected";
    actionLabel = "View characters";
    actionTo = "/characters";
  } else if (isError) {
    title = "Connection failed";
    description = message ?? "Battle.net authentication unsuccessful";
    actionLabel = "Try again";
    actionTo = "/";
  }

  return (
    <AppShell>
      <div className="py-8">
        <Panel className="p-8">
          <p className="text-xs uppercase tracking-[0.35em] text-(--text-muted)">
            {provider === "battle_net" ? "Battle.net" : "Authentication"}
          </p>

          <h1 className="mt-4 text-4xl text-(--text-ink)">{title}</h1>

          <p className="mt-4 max-w-2xl text-base leading-7 text-(--text-soft)">
            {description}
          </p>

          <div className="mt-8 flex flex-wrap gap-3">
            <Link to={actionTo} className="forge-button px-5 py-3">
              {actionLabel}
            </Link>

            {isSuccess && (
              <Link
                to="/"
                className="forge-button forge-button--secondary px-5 py-3"
              >
                Return home
              </Link>
            )}
          </div>
        </Panel>
      </div>
    </AppShell>
  );
}
