/**
 * StatisticsScreen — mockups/f/PLAN.md §3.1 (`a-dash`), the console's home
 * page (routes.tsx redirects "/" here).
 *
 * Accent discipline (PLAN.md §1's table for this screen): the "Active
 * leads" tile is the one full-lime element — every other tile stays the
 * neutral/`ok` palette, and the period segmented control below uses Seg's
 * existing dark "on" state, not a second accent.
 *
 * Three real, differently-shaped data-honesty calls this screen makes,
 * beyond the shared Flag components:
 *  - "Ads created"/"Ads sold" render GET /statistics/ads's own counts for
 *    whichever period is selected, verbatim. PLAN.md's wireframe wants a
 *    "+12 vs last month" delta next to each — that endpoint returns one
 *    count for one period with no previous-period figure to diff against
 *    (see deriveStatistics.ts's file header), so the delta is omitted
 *    entirely rather than invented.
 *  - The period control offers Today / This week / This month / All time —
 *    GET /statistics/ads's real `filterType` enum (apps/api/src/routes/
 *    statistics.js's dateRangeFor) — not PLAN's literal "Month/Quarter/
 *    Year", which this endpoint has no way to compute.
 *  - The "Created vs sold" panel renders the two real period totals as a
 *    simple two-bar comparison, not PLAN's 12-day daily series: the API has
 *    no per-day breakdown at all (a gap beyond the ones PLAN.md §4 already
 *    names), so a day-by-day chart would be fabricated from nothing. A
 *    <Flag> says so instead of drawing one anyway.
 *
 * The "Recent activity" list (PLAN.md §3.1's fifth block) is not rendered
 * at all — src/data/useStatistics.ts's own file header already documents
 * why: there is no activity-feed endpoint, and CoworkerStatisticEvent rows
 * carry no human-readable sentence to build one out of. A <Flag> names the
 * gap in its place.
 */
import { useState, type ReactNode } from "react";
import { useAdsStatistics, useCoworkerStatistics } from "@/data/useStatistics";
import { useLeads } from "@/data/useLeads";
import { useCoworkers } from "@/data/useCoworkers";
import { PageHead } from "@/shell/PageHead";
import { Panel, PanelHead } from "@/ui/Panel";
import { Flag } from "@/ui/Flag";
import { Seg, type SegOption } from "@/ui/Seg";
import clsx from "clsx";
import { countCallbacksDueToday, countCoworkersActiveThisWeek } from "./deriveStatistics";

type Period = "today" | "thisWeek" | "thisMonth" | "all";

const PERIOD_OPTIONS: ReadonlyArray<SegOption<Period>> = [
  { value: "today", label: "Today" },
  { value: "thisWeek", label: "This week" },
  { value: "thisMonth", label: "This month" },
  { value: "all", label: "All time" },
];

export function StatisticsScreen() {
  const [period, setPeriod] = useState<Period>("thisMonth");

  const adsStats = useAdsStatistics(period);
  const leads = useLeads();
  const coworkers = useCoworkers();
  const coworkerEvents = useCoworkerStatistics();

  const activeLeadsCount = leads.isLoading ? undefined : leads.isError ? null : (leads.data?.length ?? 0);
  const callbacksDueToday = leads.data ? countCallbacksDueToday(leads.data) : undefined;

  const coworkersCount = coworkers.isLoading ? undefined : coworkers.isError ? null : (coworkers.data?.length ?? 0);
  const activeThisWeek = coworkerEvents.data ? countCoworkersActiveThisWeek(coworkerEvents.data) : undefined;

  return (
    <>
      <PageHead crumb="Console · Workspace" title="Statistics" />

      <div className="mb-4 grid grid-cols-4 gap-4">
        <StatTile
          label="Ads created"
          value={adsStats.isLoading ? undefined : adsStats.isError ? null : adsStats.data?.adsNewCount}
          sub={<PeriodLabel period={period} />}
        />
        <StatTile
          label="Ads sold"
          value={adsStats.isLoading ? undefined : adsStats.isError ? null : adsStats.data?.adsSoldCount}
          sub={<PeriodLabel period={period} />}
        />
        <StatTile
          label="Active leads"
          value={activeLeadsCount}
          sub={
            callbacksDueToday !== undefined ? (
              <span className="inline-flex items-center gap-1.5">
                <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-accent-text" />
                {callbacksDueToday} need{callbacksDueToday === 1 ? "s" : ""} a callback today
              </span>
            ) : undefined
          }
          loud
        />
        <StatTile
          label="Coworkers"
          value={coworkersCount}
          sub={activeThisWeek !== undefined ? `${activeThisWeek} active this week` : undefined}
        />
      </div>

      <Panel className="mb-4">
        <PanelHead title="Ads created vs sold" sub={<PeriodLabel period={period} lowercaseFirst />}>
          <Seg options={PERIOD_OPTIONS} value={period} onChange={setPeriod} />
        </PanelHead>

        <Flag>
          There is no day-by-day breakdown to chart — GET /statistics/ads returns one total per period, not a
          time series. The bars below are the two real period totals, not a daily trend.
        </Flag>

        {/* Error first, then absent-data. `isLoading` alone doesn't narrow
            `data` — a settled query can still hold `undefined` (a refetch
            after an error, a disabled-then-enabled query), so the bars are
            gated on the data actually being there rather than on the
            loading flag being false. */}
        {adsStats.isError ? (
          <p className="py-10 text-center text-small text-err">Couldn&apos;t load ad statistics.</p>
        ) : !adsStats.data ? (
          <p className="py-10 text-center text-small text-ink-2">Loading…</p>
        ) : (
          <CreatedVsSoldBars created={adsStats.data.adsNewCount} sold={adsStats.data.adsSoldCount} />
        )}
      </Panel>

      <Panel>
        <PanelHead title="Recent activity" />
        <Flag>
          There is no activity-feed endpoint yet — CoworkerStatisticEvent rows (
          <span className="font-mono">GET /statistics/coworkers</span>) carry only{" "}
          <span className="font-mono">{"{ stage, adId, leadId, createdAt }"}</span>, no human-readable sentence to
          build a feed row out of.
        </Flag>
      </Panel>
    </>
  );
}

function PeriodLabel({ period, lowercaseFirst }: { period: Period; lowercaseFirst?: boolean }) {
  const label = PERIOD_OPTIONS.find((option) => option.value === period)?.label ?? "";
  const text = typeof label === "string" && lowercaseFirst ? label.charAt(0).toLowerCase() + label.slice(1) : label;
  return <>{text}</>;
}

function StatTile({
  label,
  value,
  sub,
  loud,
}: {
  label: string;
  /** undefined = loading, null = failed to load, number = real value. */
  value: number | null | undefined;
  sub?: ReactNode;
  loud?: boolean;
}) {
  return (
    <div
      className={clsx(
        "rounded-card border p-[22px]",
        loud ? "border-transparent bg-accent text-accent-text" : "border-black/[.03] bg-surface text-ink",
      )}
    >
      <div className={clsx("text-caption font-medium", loud ? "text-accent-text/80" : "text-ink-2")}>{label}</div>
      <div className="mt-1 text-stat font-semibold tracking-display tabular-nums">
        {value === undefined ? "…" : value === null ? "—" : value}
      </div>
      {sub !== undefined ? (
        <div className={clsx("mt-1.5 text-caption", loud ? "text-accent-text/80" : "text-ink-2")}>{sub}</div>
      ) : null}
    </div>
  );
}

/** A real-totals-only stand-in for PLAN.md §3.1's 12-day dual-series chart —
 * see the file header for why a day-by-day series isn't available. Heights
 * are proportional to the larger of the two counts; both bars render at a
 * minimum visible height even at 0 so "no ads this period" doesn't look
 * like a rendering bug. */
function CreatedVsSoldBars({ created, sold }: { created: number; sold: number }) {
  const max = Math.max(created, sold, 1);
  const createdHeight = Math.max((created / max) * 100, created > 0 ? 6 : 2);
  const soldHeight = Math.max((sold / max) * 100, sold > 0 ? 6 : 2);

  return (
    <div className="flex h-[160px] items-end gap-6 px-2 pt-4">
      <Bar label="Created" value={created} heightPct={createdHeight} className="bg-accent" />
      <Bar label="Sold" value={sold} heightPct={soldHeight} className="border-1.5 border-dashed border-ink/30 bg-transparent" />
    </div>
  );
}

function Bar({
  label,
  value,
  heightPct,
  className,
}: {
  label: string;
  value: number;
  heightPct: number;
  className: string;
}) {
  return (
    <div className="flex h-full w-16 flex-col items-center justify-end gap-2">
      <span className="text-caption font-semibold tabular-nums text-ink">{value}</span>
      <div className={clsx("w-full rounded-t-input", className)} style={{ height: `${heightPct}%` }} />
      <span className="text-tiny text-ink-2">{label}</span>
    </div>
  );
}
