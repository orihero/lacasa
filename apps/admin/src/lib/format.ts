/**
 * src/lib/format — the control room's display formatters.
 *
 * Dates reuse @lacasa/domain/formatting/date (toValidDate, formatCreatedAt)
 * rather than re-parsing the `{ seconds: number }` / ISO-string / Date union
 * by hand — see that module's file comment for why ads and leads still carry
 * the Firestore-era `{ seconds }` shape on the wire.
 *
 * Everything here formats a RECORD, not a property: counts are grouped and
 * tabular, ids are truncated to a scannable prefix, and a missing value is an
 * em dash rather than a fabricated zero. That last rule matters more on this
 * surface than anywhere else in the monorepo — a "0" in the ads column of a
 * user row is a claim that they have no listings, and an admin may demote an
 * account on the strength of it.
 */
import { formatCreatedAt, toValidDate, type DateLike } from "@lacasa/domain";

export type { DateLike };

/** The one "no value" glyph. Never a 0, never an empty cell, never "N/A". */
export const EM_DASH = "—";

/** "03.08.2026 | 11:42" — the mockup's record timestamp. */
export function formatDateTime(input: DateLike): string {
  return formatCreatedAt(input) || EM_DASH;
}

/** "03.08.2026" — for columns where the time of day is noise (Created, Since). */
export function formatDate(input: DateLike): string {
  const date = toValidDate(input);
  if (!date) return EM_DASH;
  return date
    .toLocaleDateString("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" })
    .replaceAll("/", ".");
}

/**
 * "12:41:08" — the audit log's leading column. Seconds are included because
 * audit rows arrive in bursts: three events inside the same minute are
 * indistinguishable without them, and the order of those three is often the
 * whole question being asked.
 */
export function formatTimeOfDay(input: DateLike): string {
  const date = toValidDate(input);
  if (!date) return EM_DASH;
  return date.toLocaleTimeString("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
}

/**
 * "1,284" — grouped, and `EM_DASH` for a count that did not arrive. A count
 * this surface cannot vouch for must not render as 0 (see the file header).
 */
export function formatCount(value: number | null | undefined): string {
  if (value === null || value === undefined || !Number.isFinite(value)) return EM_DASH;
  return new Intl.NumberFormat("en-US").format(value);
}

/**
 * "a3f21e08…" — a UUID's first segment, which is what the mockup's mono id
 * column shows and what an admin actually pattern-matches against when
 * cross-referencing a row with a log line. The full id stays available to the
 * caller for `title`/copy affordances; this is a display truncation only, and
 * anything that has to be exact (a URL, a support ticket) must use the id
 * itself, not this.
 */
export function shortId(id: string | null | undefined, length = 8): string {
  if (!id) return EM_DASH;
  if (id.length <= length) return id;
  return `${id.slice(0, length)}…`;
}

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/**
 * "2 days" / "5 h" / "18 min" — the age of the OLDEST thing in a queue
 * ("Oldest: 2 days"), which is the number that says whether a queue is
 * healthy. Deliberately a bare duration with no "ago": the callers phrase it
 * themselves, and "Oldest: 2 days ago" reads wrong.
 *
 * A timestamp slightly in the future (clock skew between the API host and the
 * admin's laptop) collapses to "just now" rather than a nonsensical "-1 min".
 */
export function formatAge(input: DateLike, now: Date = new Date()): string {
  const date = toValidDate(input);
  if (!date) return EM_DASH;

  const diffMs = now.getTime() - date.getTime();
  if (diffMs < MINUTE) return "just now";
  if (diffMs < HOUR) return `${Math.floor(diffMs / MINUTE)} min`;
  if (diffMs < DAY) return `${Math.floor(diffMs / HOUR)} h`;
  const days = Math.floor(diffMs / DAY);
  return days === 1 ? "1 day" : `${days} days`;
}

/**
 * Deterministic 2-letter initials for Avatar's fallback chip. Splits on
 * Unicode code points, not UTF-16 code units, so a name outside the BMP
 * doesn't get cut mid-surrogate-pair.
 */
export function initials(fullName: string): string {
  const words = fullName.trim().split(/\s+/).filter(Boolean);
  const [first, second] = words;
  if (!first) return "";
  if (!second) {
    return Array.from(first).slice(0, 2).join("").toUpperCase();
  }
  const firstLetter = Array.from(first)[0] ?? "";
  const secondLetter = Array.from(second)[0] ?? "";
  return (firstLetter + secondLetter).toUpperCase();
}
