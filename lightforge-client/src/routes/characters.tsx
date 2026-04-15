import { Link } from "@tanstack/react-router";
import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";
import { useCharacters } from "../features/characters/hooks";

function classTint(className: string | null) {
  switch ((className ?? "").toLowerCase()) {
    case "death knight":
      return {
        dot: "#c41e3a",
      };
    case "demon hunter":
      return {
        dot: "#a330c9",
      };
    case "druid":
      return {
        dot: "#ff7d0a",
      };
    case "evoker":
      return {
        dot: "#33937f",
      };
    case "hunter":
      return {
        dot: "#aad372",
      };
    case "mage":
      return {
        dot: "#3fc7eb",
      };
    case "monk":
      return {
        dot: "#00ff98",
      };
    case "paladin":
      return {
        dot: "#f48cba",
      };
    case "priest":
      return {
        dot: "#d7cdbf",
      };
    case "rogue":
      return {
        dot: "#fff468",
      };
    case "shaman":
      return {
        dot: "#0070dd",
      };
    case "warlock":
      return {
        dot: "#8788ee",
      };
    case "warrior":
      return {
        dot: "#c69b6d",
      };
    default:
      return {
        dot: "#8b7461",
      };
  }
}

export function CharactersPage() {
  const charactersQuery = useCharacters();

  return (
    <AppShell>
      <div className="grid gap-6 py-8">
        {charactersQuery.isPending && (
          <Panel className="p-6">
            <p className="text-sm text-(--text-muted)">Loading roster...</p>
          </Panel>
        )}

        {charactersQuery.isError && (
          <Panel className="p-6">
            <p className="text-sm text-red-700">Could not load characters.</p>
          </Panel>
        )}

        {charactersQuery.data && charactersQuery.data.data.length === 0 && (
          <Panel className="p-7 lg:p-8">
            <div className="forge-section-heading">
              <p className="forge-section-kicker">Roster</p>
              <h1 className="text-3xl text-(--text-ink)">Available profiles</h1>
            </div>

            <div className="mt-4 flex flex-wrap gap-2">
              <span className="forge-data-chip">0 stored</span>
            </div>

            <p className="mt-6 max-w-xl text-sm leading-6 text-(--text-soft)">
              Connect Battle.net, then sync a character so the roster can start
              filling with profiles.
            </p>

            <div className="mt-6 flex flex-wrap gap-3">
              <a href="/character" className="forge-button px-5 py-3">
                Sync your first character
              </a>
            </div>
          </Panel>
        )}

        {charactersQuery.data && charactersQuery.data.data.length > 0 && (
          <Panel className="p-7 lg:p-8">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
              <div className="forge-section-heading">
                <p className="forge-section-kicker">Roster</p>
                <h1 className="text-3xl text-(--text-ink)">
                  Available profiles
                </h1>
              </div>

              <div className="flex flex-wrap gap-2">
                <span className="forge-data-chip">
                  {charactersQuery.data.data.length} stored
                </span>
                <a
                  href="/character"
                  className="forge-button forge-button--secondary px-4 py-2"
                >
                  Sync character
                </a>
              </div>
            </div>

            <div className="mt-6 max-w-3xl space-y-3">
              {charactersQuery.data.data.map((character) => {
                const tint = classTint(character.class_name);

                return (
                  <Link
                    key={character.id}
                    to="/characters/$region/$realm/$name"
                    params={{
                      region: character.region,
                      realm: character.realm_slug,
                      name: character.name,
                    }}
                    className="forge-roster-chip"
                  >
                    <div className="flex min-w-0 items-center gap-3">
                      <span
                        className="forge-roster-chip__dot"
                        style={{ background: tint.dot }}
                      />

                      <span className="min-w-0">
                        <span className="block truncate text-base font-medium text-(--text-ink)">
                          {character.name}
                        </span>
                        <span className="block truncate text-xs uppercase tracking-[0.18em] text-(--text-muted)">
                          {character.class_name ?? "Unknown"} ·{" "}
                          {character.spec_name ?? "Unknown spec"}
                        </span>
                      </span>
                    </div>

                    <div className="flex items-center gap-3 pl-2">
                      <span className="hidden sm:block forge-roster-chip__meta">
                        {character.realm}
                      </span>
                      <span className="flex h-9 w-9 items-center justify-center rounded-full border border-[rgba(110,73,34,0.16)] bg-[rgba(255,249,239,0.76)] text-base text-(--text-ink) shadow-[inset_0_1px_0_rgba(255,252,246,0.52)]">
                        ›
                      </span>
                    </div>
                  </Link>
                );
              })}
            </div>
          </Panel>
        )}
      </div>
    </AppShell>
  );
}
