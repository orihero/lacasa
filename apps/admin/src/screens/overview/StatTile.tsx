/**
 * StatTile — the overview's `.kpi` tile (mockups/build/web-admin.src.html's
 * `.kpi` / `.kpi--alert`). Lives in this screen's folder rather than src/ui/
 * because the overview is the only surface with a KPI row; if a second screen
 * ever needs one, that is the moment to promote it, not now.
 *
 * TWO RULES ARE ENCODED HERE AND BOTH ARE ABOUT HONESTY, NOT LOOKS:
 *
 * 1. `signal` (amber) turns on ONLY when the number is greater than zero. The
 *    control room has exactly one attention colour (tailwind.config.js rule 2)
 *    and on this screen it is spent on the two figures an admin can act on —
 *    pending applications and failed publications. A queue of zero is not
 *    waiting on anybody, so an amber "0" would train an admin to ignore the
 *    colour on the day it means something. A count that failed to arrive
 *    (`undefined`) is likewise not an alert: it is an unknown, and it renders
 *    as `formatCount`'s em dash.
 *
 * 2. `value` goes through `formatCount`, which renders a missing count as "—"
 *    rather than 0 (see lib/format.ts's header). A tile is a claim about the
 *    platform; "0 pending applications" and "we could not read the pending
 *    count" are opposite claims and must not look the same.
 *
 * A tile with `to` is a whole-tile link — the actionable numbers should be one
 * click from the screen that acts on them, and a 24px numeral is a much easier
 * target than a caret tucked in a corner. Tiles without `to` are plain
 * readouts and stay inert; nothing on this screen navigates by surprise.
 */
import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import clsx from "clsx";
import { formatCount } from "@/lib/format";
import { ArrowRightIcon } from "@/ui/icons";

export interface StatTileProps {
  /** The uppercase caps label. Also the tile's accessible name when it links. */
  label: string;
  value: number | null | undefined;
  /** The quiet second line: a breakdown, a denominator, or "Queue clear". */
  sub?: ReactNode;
  /** Amber-when-nonzero. Reserved — see rule 1 above. */
  signal?: boolean;
  /** Where the number is acted on. Renders the tile as a link when set. */
  to?: string;
}

export function StatTile({ label, value, sub, signal = false, to }: StatTileProps) {
  const alert = signal && typeof value === "number" && Number.isFinite(value) && value > 0;

  const body = (
    <>
      <div className="flex items-center gap-1.5">
        <span className="text-caps font-bold uppercase tracking-caps-wide text-muted">{label}</span>
        {to ? (
          <ArrowRightIcon
            size={11}
            aria-hidden="true"
            className={clsx(
              "ml-auto flex-none transition-colors",
              alert ? "text-acc" : "text-faint group-hover:text-ink-2",
            )}
          />
        ) : null}
      </div>
      <div
        className={clsx(
          "mb-[3px] mt-1.5 text-kpi font-bold leading-none tracking-display tabular-nums",
          alert ? "text-acc" : "text-ink",
        )}
      >
        {formatCount(value)}
      </div>
      {sub != null ? <div className="text-tiny font-semibold text-muted">{sub}</div> : null}
    </>
  );

  const shell = clsx(
    "block rounded-panel border px-[14px] py-[13px] shadow-panel",
    // The mockup's `.kpi--alert`: an amber hairline plus a wash that fades out
    // before the second line. `to-card` rather than `to-transparent` because
    // the tile paints its own `bg-card` underneath, so the two are the same
    // gradient with one fewer alpha blend.
    alert ? "border-acc-line bg-card bg-gradient-to-b from-acc-soft to-card" : "border-line bg-card",
  );

  if (!to) return <div className={shell}>{body}</div>;

  return (
    <Link
      to={to}
      className={clsx(
        shell,
        "group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc focus-visible:ring-offset-2 focus-visible:ring-offset-app",
      )}
    >
      {body}
    </Link>
  );
}
