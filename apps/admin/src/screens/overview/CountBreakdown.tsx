/**
 * CountBreakdown — a labelled count list with a proportional bar, used by the
 * overview's two distribution panels (the lead pipeline and the publication
 * outcomes). The mockup's `.bar`, in list form.
 *
 * DELIBERATELY COLOURLESS. @/lib/labels gives every one of these buckets a
 * Tag tone, and rendering them here would put amber on `need_to_call_back` and
 * on `drafted_awaiting_review` — but on THIS screen amber is spent on the two
 * tiles an admin can act on, and a third and fourth amber mark two panels down
 * would dilute exactly the signal the tiles exist to carry. The bars are
 * neutral ink; the tones stay meaningful on the screens that act on those rows.
 *
 * The bar is `aria-hidden` and carries no number of its own: it is a shape
 * that makes the distribution scannable, and the count next to it is the fact.
 * A row whose count did not arrive renders as an em dash with an empty bar
 * rather than as a confident zero-width zero (lib/format.ts's rule).
 */
import { formatCount } from "@/lib/format";

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
    <dl className="flex flex-col gap-2.5 px-[15px] py-[13px]">
      {rows.map((row) => {
        const share = total > 0 && row.value ? Math.min(100, (row.value / total) * 100) : 0;
        return (
          <div key={row.key} className="grid grid-cols-[1fr_auto] items-baseline gap-x-3">
            <dt className="truncate text-small text-ink-2">{row.label}</dt>
            <dd className="font-mono text-record tabular-nums text-ink">
              {formatCount(row.value)}
            </dd>
            <div
              aria-hidden="true"
              className="col-span-2 mt-1.5 h-1.5 overflow-hidden rounded-act bg-sunk"
            >
              <span className="block h-full rounded-act bg-muted" style={{ width: `${share}%` }} />
            </div>
          </div>
        );
      })}
    </dl>
  );
}
