/**
 * CountBreakdown — a labelled count list with a proportional bar, used by the
 * overview's two distribution panels (the lead pipeline and the publication
 * outcomes).
 *
 * DELIBERATELY COLOURLESS. `@/lib/labels` gives several of these buckets a Tag
 * tone, and rendering them here would put accent yellow on `need_to_call_back`
 * and on `drafted_awaiting_review` — but on THIS screen the accent is spent on
 * the two tiles an admin can act on, and a third and fourth mark two panels
 * down would dilute exactly the signal those tiles exist to carry. The bars are
 * neutral ink; the tones stay meaningful on the screens that act on those rows.
 * This is an intentional deviation, not an oversight.
 *
 * Publication status and lead status also render as PLAIN TEXT here, never as a
 * `Tag` (PRECEDENCE.md, factual correction 5) — which is why neither has a tone
 * map in `@/lib/labels` at all.
 *
 * The bar is `aria-hidden` and carries no number of its own: it is a shape that
 * makes the distribution scannable, and the count next to it is the fact. A row
 * whose count did not arrive renders as an em dash with an empty bar rather
 * than as a confident zero-width zero (lib/format.ts's rule).
 */
import { formatCount } from "@/lib/format";
import "./countBreakdown.scss";

export interface BreakdownRow {
  /** Stable react key — the wire key of the bucket. */
  key: string;
  label: string;
  /** `undefined` when the payload had no such bucket, NOT when it had zero. */
  value: number | undefined;
}

/**
 * `total` is passed in rather than summed from `rows` because the API already
 * reports one for the lead pipeline (`leads.total`), and a bar scaled to a
 * locally-summed denominator would silently disagree with it the moment the
 * server adds a bucket this build does not render.
 */
export function CountBreakdown({ rows, total }: { rows: BreakdownRow[]; total: number }) {
  return (
    <dl className="breakdown">
      {rows.map((row) => {
        // The truthiness check on `row.value` is load-bearing: a value of 0 AND
        // a value of undefined both give a share of 0, and a total of 0 gives
        // every row a share of 0. The clamp guards a bucket that exceeds a
        // stale total.
        const share = total > 0 && row.value ? Math.min(100, (row.value / total) * 100) : 0;
        return (
          <div className="breakdown__row" key={row.key}>
            <dt className="breakdown__label">{row.label}</dt>
            <dd className="breakdown__value">{formatCount(row.value)}</dd>
            <div className="breakdown__bar" aria-hidden="true">
              <span className="breakdown__fill" style={{ width: `${share}%` }} />
            </div>
          </div>
        );
      })}
    </dl>
  );
}
