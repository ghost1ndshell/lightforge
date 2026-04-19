import { Link, useMatch } from "@tanstack/react-router";
import { AppShell } from "../components/layout/AppShell";
import { Panel } from "../components/ui/Panel";
import { useCharacterGearing } from "../features/characters/hooks";

function formatTimestamp(value: string | null | undefined) {
  if (!value) {
    return "Unknown";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

function modeLabel(mode: "dungeons" | "raid") {
  return mode === "raid" ? "Raid" : "Dungeons";
}

function urgencyLabel(urgency: string) {
  if (urgency === "fix_now") {
    return "Fix now";
  }

  if (urgency === "upgrade_next") {
    return "Upgrade next";
  }

  return "Stable";
}

function urgencyClasses(urgency: string) {
  if (urgency === "fix_now") {
    return "border-[rgba(191,67,56,0.22)] bg-[rgba(255,242,239,0.78)] text-[#8f3d32]";
  }

  if (urgency === "upgrade_next") {
    return "border-[rgba(186,126,50,0.22)] bg-[rgba(255,248,236,0.82)] text-[#8b5f2f]";
  }

  return "border-[rgba(92,78,66,0.16)] bg-[rgba(255,250,243,0.7)] text-[color:var(--text-soft)]";
}

function statusLabel(status: string) {
  if (status === "owned") {
    return "Owned";
  }

  if (status === "major_upgrade") {
    return "Major upgrade";
  }

  if (status === "solid_upgrade") {
    return "Strong upgrade";
  }

  if (status === "missing") {
    return "Missing slot";
  }

  return "Low priority";
}

function tierClasses(tier: string) {
  if (tier === "best") {
    return "border-[rgba(69,223,242,0.24)] bg-[rgba(243,252,253,0.92)] text-[#25646d]";
  }

  if (tier === "strong") {
    return "border-[rgba(145,97,48,0.18)] bg-[rgba(255,247,236,0.84)] text-[#7a5534]";
  }

  return "border-[rgba(133,92,198,0.16)] bg-[rgba(249,245,255,0.88)] text-[#7153a8]";
}

export function CharacterGearingPage() {
  const match = useMatch({
    from: "/characters/$region/$realm/$name/forge-path/$mode",
  });
  const { region, realm, name } = match.params;
  const mode = match.params.mode === "raid" ? "raid" : "dungeons";

  const gearingQuery = useCharacterGearing(region, realm, name, mode);
  const plan = gearingQuery.data?.data;
  const trinketTargets =
    plan?.top_targets.filter((target) => target.slot === "Trinket") ?? [];

  return (
    <AppShell>
      <div className="grid gap-6 py-8">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <Link
            to="/characters/$region/$realm/$name"
            params={{ name, realm, region }}
            className="forge-button forge-button--secondary px-4 py-2"
          >
            Back to character
          </Link>

          <div className="flex flex-wrap items-center gap-2 rounded-full border border-[rgba(110,73,34,0.16)] bg-[rgba(255,249,240,0.72)] p-1 shadow-[inset_0_1px_0_rgba(255,252,246,0.48)]">
            {(["dungeons", "raid"] as const).map((nextMode) => (
              <Link
                key={nextMode}
                to="/characters/$region/$realm/$name/forge-path/$mode"
                params={{ mode: nextMode, name, realm, region }}
                className={[
                  "rounded-full px-4 py-2 text-sm font-semibold tracking-[0.03em] transition",
                  nextMode === mode
                    ? "bg-[linear-gradient(180deg,rgba(142,84,34,0.96),rgba(107,62,28,0.94))] text-[#fff4e6] shadow-[0_12px_20px_rgba(102,62,28,0.18)]"
                    : "text-[color:var(--text-soft)] hover:bg-[rgba(255,252,246,0.84)]",
                ].join(" ")}
              >
                {modeLabel(nextMode)}
              </Link>
            ))}
          </div>
        </div>

        {gearingQuery.isPending && (
          <Panel className="p-6">
            <p className="text-sm text-[color:var(--text-muted)]">
              Loading Forge Path briefing...
            </p>
          </Panel>
        )}

        {gearingQuery.isError && (
          <Panel className="p-6">
            <p className="text-sm text-red-700">
              Could not load this character&apos;s gearing route.
            </p>
          </Panel>
        )}

        {plan && (
          <>
            <Panel className="p-8">
              <div className="grid gap-8 xl:grid-cols-[1.3fr_0.9fr]">
                <div className="space-y-6">
                  <div>
                    <p className="forge-section-kicker">Forge Path</p>
                    <h1 className="mt-4 text-5xl text-[color:var(--text-ink)]">
                      {plan.character.name}
                    </h1>
                    <p className="mt-3 text-base text-[color:var(--text-soft)]">
                      {plan.character.spec_name ?? "Unknown spec"}{" "}
                      {plan.character.class_name ?? "Unknown class"} ·{" "}
                      {plan.character.realm} · {plan.character.region.toUpperCase()}
                    </p>

                    <div className="mt-5 flex flex-wrap gap-2">
                      <span className="forge-data-chip">
                        {modeLabel(plan.mode)}
                      </span>
                      <span className="forge-data-chip">{plan.meta.season}</span>
                      {plan.meta.reviewed_on && (
                        <span className="forge-data-chip">
                          Reviewed {plan.meta.reviewed_on}
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="rounded-[1.75rem] border border-[rgba(110,73,34,0.14)] bg-[linear-gradient(135deg,rgba(255,251,245,0.94),rgba(244,232,214,0.86))] px-6 py-6 shadow-[inset_0_1px_0_rgba(255,252,246,0.56),0_18px_36px_rgba(113,78,45,0.08)]">
                    <p className="forge-section-kicker">Briefing</p>
                    <h2 className="mt-3 text-3xl text-[color:var(--text-ink)]">
                      {plan.summary.headline}
                    </h2>
                    <p className="mt-4 max-w-2xl text-base leading-7 text-[color:var(--text-soft)]">
                      {plan.summary.subheadline}
                    </p>
                    <p className="mt-4 text-sm leading-6 text-[color:var(--text-soft)]">
                      {plan.meta.note}
                    </p>
                  </div>
                </div>

                <div className="grid gap-3">
                  <div className="forge-metric-tile">
                    <p className="forge-section-kicker">Item Level</p>
                    <p className="mt-3 text-4xl text-[color:var(--text-ink)]">
                      {plan.snapshot.equipped_item_level ?? "?"}
                    </p>
                    <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                      Current equipped benchmark
                    </p>
                  </div>

                  <div className="forge-metric-tile">
                    <p className="forge-section-kicker">Targets</p>
                    <p className="mt-3 text-4xl text-[color:var(--text-ink)]">
                      {plan.top_targets.length}
                    </p>
                    <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                      Curated upgrade paths surfaced for this mode
                    </p>
                  </div>

                  <div className="forge-metric-tile">
                    <p className="forge-section-kicker">Snapshot</p>
                    <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                      {formatTimestamp(plan.snapshot.captured_at)}
                    </p>
                    <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                      Latest stored profile refresh
                    </p>
                  </div>
                </div>
              </div>
            </Panel>

            <div className="grid gap-6 xl:grid-cols-[1.15fr_0.85fr]">
              <div className="grid gap-6">
                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Top Targets</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Small list, high leverage
                    </h2>
                  </div>

                  {plan.top_targets.length > 0 ? (
                    <div className="mt-5 grid gap-4">
                      {plan.top_targets.map((target) => (
                        <article
                          key={`${target.slot}-${target.target_name}`}
                          className="rounded-[1.6rem] border border-[rgba(110,73,34,0.14)] bg-[rgba(255,250,243,0.78)] p-5 shadow-[inset_0_1px_0_rgba(255,252,246,0.56)]"
                        >
                          <div className="flex flex-wrap items-start justify-between gap-3">
                            <div className="min-w-0">
                              <p className="forge-section-kicker">{target.slot}</p>
                              <h3 className="mt-2 text-2xl text-[color:var(--text-ink)]">
                                {target.target_name}
                              </h3>
                              <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                                {target.source_type} · {target.source_name}
                              </p>
                            </div>

                            <div className="flex flex-wrap items-center gap-2">
                              <span
                                className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] ${tierClasses(target.tier)}`}
                              >
                                {target.tier}
                              </span>
                              <span className="forge-data-chip">
                                {statusLabel(target.status)}
                              </span>
                            </div>
                          </div>

                          <p className="mt-4 text-sm leading-6 text-[color:var(--text-soft)]">
                            {target.reason}
                          </p>

                          <div className="mt-4 grid gap-3 sm:grid-cols-2">
                            <div className="forge-quiet-panel">
                              <p className="forge-section-kicker">Current</p>
                              <p className="mt-2 text-base text-[color:var(--text-ink)]">
                                {target.current_item_name}
                              </p>
                            </div>

                            <div className="forge-quiet-panel">
                              <p className="forge-section-kicker">Target Hint</p>
                              <p className="mt-2 text-base text-[color:var(--text-ink)]">
                                {target.target_item_level_hint
                                  ? `Around ${target.target_item_level_hint} ilvl`
                                  : "Curated chase piece"}
                              </p>
                            </div>
                          </div>
                        </article>
                      ))}
                    </div>
                  ) : (
                    <div className="forge-quiet-panel mt-5">
                      <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                        No curated target list is published for this spec and mode
                        yet.
                      </p>
                    </div>
                  )}
                </Panel>

                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">This Week</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Route the effort
                    </h2>
                  </div>

                  {plan.weekly_route.length > 0 ? (
                    <div className="mt-5 grid gap-3">
                      {plan.weekly_route.map((step) => (
                        <div
                          key={`${step.source_type}-${step.source_name}`}
                          className="forge-quiet-panel"
                        >
                          <div className="flex flex-wrap items-center justify-between gap-3">
                            <div>
                              <p className="forge-section-kicker">
                                {step.source_type}
                              </p>
                              <h3 className="mt-2 text-xl text-[color:var(--text-ink)]">
                                {step.label}
                              </h3>
                            </div>
                            <span className="forge-data-chip">{step.source_name}</span>
                          </div>
                          <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                            {step.reason}
                          </p>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="forge-quiet-panel mt-5">
                      <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                        Weekly routing will appear here once curated targets exist
                        for this spec.
                      </p>
                    </div>
                  )}
                </Panel>
              </div>

              <div className="grid gap-6">
                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Priority Slots</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      What to fix first
                    </h2>
                  </div>

                  {plan.priority_slots.length > 0 ? (
                    <div className="mt-5 grid gap-3">
                      {plan.priority_slots.map((slot) => (
                        <div
                          key={slot.slot}
                          className="rounded-[1.45rem] border border-[rgba(110,73,34,0.14)] bg-[rgba(255,250,243,0.78)] p-4 shadow-[inset_0_1px_0_rgba(255,252,246,0.56)]"
                        >
                          <div className="flex flex-wrap items-center justify-between gap-3">
                            <h3 className="text-xl text-[color:var(--text-ink)]">
                              {slot.slot}
                            </h3>
                            <span
                              className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] ${urgencyClasses(slot.urgency)}`}
                            >
                              {urgencyLabel(slot.urgency)}
                            </span>
                          </div>
                          <p className="mt-3 text-sm leading-6 text-[color:var(--text-soft)]">
                            {slot.reason}
                          </p>
                          <p className="mt-3 text-sm text-[color:var(--text-muted)]">
                            Current ilvl: {slot.current_item_level ?? "Unknown"}
                          </p>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="forge-quiet-panel mt-5">
                      <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                        Priority slots appear once the route has something worth
                        chasing.
                      </p>
                    </div>
                  )}
                </Panel>

                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Trinket Board</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Current and chase pieces
                    </h2>
                  </div>

                  <div className="mt-5 grid gap-3">
                    {plan.current_trinkets.length > 0 ? (
                      plan.current_trinkets.map((trinket) => (
                        <div
                          key={`${trinket.slot}-${trinket.item_name}`}
                          className="forge-quiet-panel"
                        >
                          <p className="forge-section-kicker">
                            {trinket.slot ?? "Trinket"}
                          </p>
                          <h3 className="mt-2 text-xl text-[color:var(--text-ink)]">
                            {trinket.item_name ?? "Unknown trinket"}
                          </h3>
                          <p className="mt-2 text-sm text-[color:var(--text-soft)]">
                            iLvl {trinket.item_level ?? "?"}
                          </p>
                        </div>
                      ))
                    ) : (
                      <div className="forge-quiet-panel">
                        <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                          No trinkets were found in the latest stored gear
                          snapshot.
                        </p>
                      </div>
                    )}
                  </div>

                  {trinketTargets.length > 0 && (
                    <div className="mt-4 rounded-[1.45rem] border border-[rgba(69,223,242,0.18)] bg-[rgba(244,252,253,0.74)] p-4">
                      <p className="forge-section-kicker">Curated Picks</p>
                      <div className="mt-3 flex flex-wrap gap-2">
                        {trinketTargets.map((target) => (
                          <span
                            key={target.target_name}
                            className="forge-data-chip"
                          >
                            {target.target_name}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </Panel>

                <Panel className="p-6">
                  <div className="forge-section-heading">
                    <p className="forge-section-kicker">Stat Direction</p>
                    <h2 className="text-3xl text-[color:var(--text-ink)]">
                      Gear should reinforce this
                    </h2>
                  </div>

                  {plan.stat_direction ? (
                    <>
                      <p className="mt-5 text-sm leading-6 text-[color:var(--text-soft)]">
                        {plan.stat_direction.note}
                      </p>

                      <div className="mt-5 grid gap-3">
                        {plan.stat_direction.focus.map((focus) => (
                          <div
                            key={focus.label}
                            className="rounded-[1.45rem] border border-[rgba(110,73,34,0.14)] bg-[rgba(255,250,243,0.78)] p-4 shadow-[inset_0_1px_0_rgba(255,252,246,0.56)]"
                          >
                            <div className="flex items-center justify-between gap-3">
                              <h3 className="text-xl text-[color:var(--text-ink)]">
                                {focus.label}
                              </h3>
                              <span className="forge-data-chip">
                                {focus.current_display}
                              </span>
                            </div>
                            <p className="mt-3 text-sm text-[color:var(--text-soft)]">
                              Target: {focus.target_display}
                            </p>
                            {typeof focus.progress === "number" && (
                              <div className="mt-3 h-1.5 rounded-full bg-[rgba(125,93,64,0.12)]">
                                <div
                                  className="h-full rounded-full bg-[linear-gradient(90deg,rgba(179,112,44,0.88),rgba(69,223,242,0.58))]"
                                  style={{
                                    width: `${Math.min(focus.progress, 100)}%`,
                                  }}
                                />
                              </div>
                            )}
                          </div>
                        ))}
                      </div>

                      {plan.stat_direction.current.length > 0 && (
                        <div className="mt-4 flex flex-wrap gap-2">
                          {plan.stat_direction.current.map((stat) => (
                            <span key={stat.label} className="forge-data-chip">
                              {stat.label} {stat.display}
                            </span>
                          ))}
                        </div>
                      )}
                    </>
                  ) : (
                    <div className="forge-quiet-panel mt-5">
                      <p className="text-sm leading-6 text-[color:var(--text-soft)]">
                        Stat direction is not available for this spec yet.
                      </p>
                    </div>
                  )}
                </Panel>
              </div>
            </div>
          </>
        )}
      </div>
    </AppShell>
  );
}
