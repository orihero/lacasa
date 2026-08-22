/**
 * src/lib/format — the control room's display formatters.
 *
 * Dates DELEGATE to @lacasa/domain's `toValidDate` / `formatCreatedAt`
 * (packages/domain/src/formatting/date.ts) rather than re-parsing the
 * `{ seconds: number }` / ISO-string / Date union by hand. That is not just
 * DRY: `formatCreatedAt` is the monorepo's record timestamp, and a
 * hand-rolled copy here is how the control room's idea of "when this
 * happened" quietly drifts away from what apps/web shows the same agent.
 * `toValidDate` also guarantees no formatter can ever emit the literal string
 * "Invalid Date".
 *
 * Everything here formats a RECORD, not a property: counts are grouped and
 * tabular, ids are truncated to a scannable prefix, and a missing value is an
 * em dash rather than a fabricated zero. That last rule matters more on this
 * surface than anywhere else in the monorepo — a "0" in the ads column of a
 * user row is a claim that they have no listings, and an admin may demote an
 * account on the strength of it.
 *
 * These are numbers and dates, not copy, so nothing here goes through i18n:
 * the whole surface reads timestamps in one locale on purpose (see
 * `formatTimeOfDay` for why the audit log cannot afford a locale-dependent
 * clock), and `EM_DASH` is a glyph, not a word.
 */
import { formatCreatedAt, toValidDate, type DateLike } from "@lacasa/domain";

export type { DateLike };

/** The one "no value" glyph. Never a 0, never an empty cell, never "N/A". */
export const EM_DASH = "—";

/**
 * "03.08.2026 | 11:42" — the record timestamp, straight from
 * @lacasa/domain's `formatCreatedAt`. That function returns "" for anything
 * that does not parse; this turns that into the em dash, because an empty
 * table cell reads as "no timestamp was recorded" rather than "the value we
 * got back was not a date".
 */
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
 *
 * Every count reaching a screen is pre-formatted by this, which is also why
 * no i18n key on this surface may use `{{count}}` — i18next reserves that
 * name for plural selection and would try to pluralise a string like "1,284".
 * The convention is `{{value}}`.
 */
export function formatCount(value: number | null | undefined): string {
  if (value === null || value === undefined || !Number.isFinite(value)) return EM_DASH;
  return new Intl.NumberFormat("en-US").format(value);
}

/**
 * "a3f21e08…" — a UUID's first segment, which is what the mono id column
 * shows and what an admin actually pattern-matches against when
 * cross-referencing a row with a log line. The full id stays available to the
 * caller for `title`/copy affordances; this is a DISPLAY TRUNCATION ONLY, and
 * anything that has to be exact (a URL, a support ticket) must use the id
 * itself, not this.
 */
export function shortId(id: string | null | undefined, length = 8): string {
  if (!id) return EM_DASH;
  if (id.length <= length) return id;
  return `${id.slice(0, length)}…`;
}

/**
 * Deterministic 2-letter initials for Avatar's fallback chip. Splits on
 * Unicode code points, not UTF-16 code units, so a name outside the BMP does
 * not get cut mid-surrogate-pair. Same person, same chip, every render — no
 * hashed hue, no procedural art (a colour derived from a name would imply a
 * category that does not exist, and on this palette it would read as a
 * status).
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
