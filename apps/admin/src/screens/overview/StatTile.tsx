/**
 * StatTile — the overview's KPI tile. Lives in this screen's folder rather than
 * `src/ui/` because the overview is the only surface with a KPI row; if a second
 * screen ever needs one, that is the moment to promote it, not now.
 *
 * The shape is apps/web's own stat card (`components/chart/components/
 * HeaderCard.jsx` + `.chart-header-card`): a white card on the white panel,
 * lifted by the house shadow `0px 0px 6px 0px rgba(0, 0, 0, 0.1)`, square
 * corners, a quiet grey label above a large black numeral. What this adds is a
 * third line — the breakdown — and the emphasis treatment described below.
 *
 * TWO RULES ARE ENCODED HERE AND BOTH ARE ABOUT HONESTY, NOT LOOKS:
 *
 * 1. `signal` turns on ONLY when the number is greater than zero. The control
 *    room has exactly one attention colour (La Casa yellow) and on this screen
 *    it is spent on the two figures an admin can act on — pending applications
 *    and failed publications. A queue of zero is not waiting on anybody, so an
 *    emphasised "0" would train an admin to ignore the treatment on the day it
 *    means something. A count that failed to arrive (`undefined`) is likewise
 *    not an alert: it is an unknown, and it renders as `formatCount`'s em dash.
 *
 * 2. `value` goes through `formatCount`, which renders a missing count as "—"
 *    rather than 0 (see lib/format.ts's header). A tile is a claim about the
 *    platform; "0 pending applications" and "we could not read the pending
 *    count" are opposite claims and must not look the same.
 *
 * WHERE THIS DEPARTS FROM THE DELETED BUILD, DELIBERATELY: there the alerted
 * numeral was painted amber. `#fece51` is a 1.7:1 contrast ratio against white
 * and apps/web never sets type in it — it is a *background* colour there, with
 * black on top. So the emphasis is carried by the tile's frame (an accent
 * hairline, an accent bar, a wash that fades out before the second line) and
 * the numeral stays ink. Still exactly one treatment, still exactly two tiles;
 * only the surface it is painted on moves.
 *
 * A tile with `to` is a whole-tile link — the actionable numbers should be one
 * click from the screen that acts on them, and a 32px numeral is a much easier
 * target than a caret tucked in a corner. Tiles without `to` are plain readouts
 * and stay inert; nothing on this screen navigates by surprise.
 */
import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { formatCount } from "@/lib/format";
import { ArrowRight } from "@/ui/icons";
import "./statTile.scss";

export interface StatTileProps {
  /** The caps label. Also the tile's accessible name when it links. */
  label: string;
  value: number | null | undefined;
  /** The quiet second line: a breakdown, a denominator, or "Queue clear". */
  sub?: ReactNode;
  /** Emphasised-when-nonzero. Reserved — see rule 1 above. */
  signal?: boolean;
  /** Where the number is acted on. Renders the tile as a link when set. */
  to?: string;
}

export function StatTile({ label, value, sub, signal = false, to }: StatTileProps) {
  const alert = signal && typeof value === "number" && Number.isFinite(value) && value > 0;

  const className = alert ? "stat-tile stat-tile--alert" : "stat-tile";

  const body = (
    <>
      <div className="stat-tile__head">
        <span className="stat-tile__label">{label}</span>
        {to ? <ArrowRight size={12} aria-hidden="true" className="stat-tile__caret" /> : null}
      </div>
      <div className="stat-tile__value">{formatCount(value)}</div>
      {sub != null ? <div className="stat-tile__sub">{sub}</div> : null}
    </>
  );

  if (!to) return <div className={className}>{body}</div>;

  return (
    <Link to={to} className={className}>
      {body}
    </Link>
  );
}
