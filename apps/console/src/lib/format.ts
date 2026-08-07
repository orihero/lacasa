/**
 * src/lib/format — the console's display formatters. Dates reuse
 * @lacasa/domain/formatting/date (toValidDate, formatCreatedAt) rather than
 * re-parsing the `{ seconds: number }` / ISO-string / Date union by hand —
 * see that module's file comment for why ads/leads still carry the
 * Firestore-era `{ seconds }` shape on the wire.
 *
 * Money and relative-time formatting live here (not in @lacasa/domain)
 * because they're presentation choices specific to this console's screens,
 * not wire-format contracts shared with the API or the extension.
 */
import { formatCreatedAt, toValidDate, type DateLike } from '@lacasa/domain';
import type { Ad } from '@lacasa/api-client';

export type { DateLike };

/**
 * `null`/`undefined` renders as an em dash — the prototype's convention for
 * "no value" (see the publish-status "external —" and channel "—" cells),
 * never a fabricated $0.
 */
export function formatMoney(amount: number | null | undefined, currency = 'USD'): string {
  if (amount === null || amount === undefined || !Number.isFinite(amount)) return '—';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

/**
 * RENT ads render "$1,000/month" — PLAN.md §4 standardises on the spelled-out
 * `/month`, retiring the old prototype's abbreviated `/mo`. `ad.price` /
 * `ad.priceType` / `ad.category` come through @lacasa/api-client's `Ad` as
 * `unknown` (that interface only names a handful of fields explicitly and
 * falls back to an index signature for the rest — see resources/ads.ts), so
 * this narrows them itself rather than trusting a cast.
 */
export function formatAdPrice(ad: Pick<Ad, 'price' | 'priceType' | 'category'>): string {
  // Number(null) is 0 and Number(undefined) is NaN — an inconsistency that
  // would make a genuinely-missing price silently render as "$0" half the
  // time. Only a number or a numeric string (the two shapes this field
  // actually arrives as) is coerced; anything else — including null and
  // undefined — goes straight to NaN, so the '—' below covers every "no
  // price" case the same way.
  const rawPrice = ad.price;
  const price = typeof rawPrice === 'number' ? rawPrice : typeof rawPrice === 'string' ? Number(rawPrice) : NaN;
  if (!Number.isFinite(price)) return '—';

  const currency = ad.priceType === 'uzs' ? 'UZS' : 'USD';
  const money = formatMoney(price, currency);
  return ad.category === 'rent' ? `${money}/month` : money;
}

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/**
 * "2 min ago" / "1 h ago" / "Yesterday" / "5 days ago" — the prototype's
 * activity-feed vocabulary (mockups/f/PLAN.md §3.1). Negative diffs (a
 * timestamp that is, by clock skew, slightly in the future) collapse to
 * "just now" rather than a nonsensical "-1 min ago".
 */
export function formatRelativeTime(input: DateLike, now: Date = new Date()): string {
  const date = toValidDate(input);
  if (!date) return '';

  const diffMs = now.getTime() - date.getTime();
  if (diffMs < MINUTE) return 'just now';
  if (diffMs < HOUR) return `${Math.floor(diffMs / MINUTE)} min ago`;
  if (diffMs < DAY) return `${Math.floor(diffMs / HOUR)} h ago`;
  if (diffMs < 2 * DAY) return 'Yesterday';
  return `${Math.floor(diffMs / DAY)} days ago`;
}

/** The prototype's "03.08.2026 | 11:42" — a thin, discoverable re-export of
 * @lacasa/domain's formatCreatedAt so screens import dates from one place
 * (`@/lib/format`) instead of reaching into `@lacasa/domain` directly for
 * this one function. */
export function formatDateTime(input: DateLike): string {
  return formatCreatedAt(input);
}

/**
 * Deterministic 2-letter initials for Avatar's fallback chip (PLAN.md §1:
 * no procedural persona art). Splits on Unicode code points, not UTF-16
 * code units, so a name outside the BMP doesn't get cut mid-surrogate-pair.
 */
export function initials(fullName: string): string {
  const words = fullName.trim().split(/\s+/).filter(Boolean);
  const [first, second] = words;
  if (!first) return '';
  if (!second) {
    return Array.from(first).slice(0, 2).join('').toUpperCase();
  }
  const firstLetter = Array.from(first)[0] ?? '';
  const secondLetter = Array.from(second)[0] ?? '';
  return (firstLetter + secondLetter).toUpperCase();
}
