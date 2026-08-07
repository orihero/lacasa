// Ported from apps/web/src/hooks/formatDate.js's formatCreatedAt /
// formatCallbackDate. `createdAt`/`updatedAt` on ads and leads still arrive
// as `{ seconds: number }` — a stale Firestore Timestamp-era shape the API
// serializers (apps/api/src/lib/adsSerializer.js, routes/leads.js) emit on
// purpose to avoid touching every consumer of formatCreatedAt() — so every
// formatter here accepts that shape alongside a real Date or ISO string,
// and returns "" instead of the literal string "Invalid Date" for anything
// that doesn't parse.

/** The three date shapes actually seen across the codebase's data. */
export type DateLike = Date | string | number | { seconds: number } | null | undefined;

function isSecondsShape(value: unknown): value is { seconds: number } {
  return (
    typeof value === 'object' &&
    value !== null &&
    'seconds' in value &&
    typeof (value as { seconds: unknown }).seconds === 'number'
  );
}

/**
 * Parses any of the supported {@link DateLike} shapes into a valid `Date`,
 * or `null` if the input is missing or doesn't produce a valid date —
 * callers never have to guard against an "Invalid Date" object themselves.
 */
export function toValidDate(input: DateLike): Date | null {
  if (input === null || input === undefined) return null;

  let date: Date;
  if (input instanceof Date) {
    date = input;
  } else if (isSecondsShape(input)) {
    date = new Date(input.seconds * 1000);
  } else {
    date = new Date(input);
  }

  return Number.isNaN(date.getTime()) ? null : date;
}

/** Matches formatDate.js's formatCreatedAt: "DD.MM.YYYY | HH:MM". */
export function formatCreatedAt(input: DateLike, locale = 'en-GB'): string {
  const date = toValidDate(input);
  if (!date) return '';
  return date
    .toLocaleString(locale, {
      hour: '2-digit',
      minute: '2-digit',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    })
    .replace(',', ' | ')
    .replaceAll('/', '.');
}

/** Matches formatDate.js's formatCallbackDate: "DD/MM/YYYY, HH:MM". */
export function formatCallbackDate(input: DateLike, locale = 'en-GB'): string {
  const date = toValidDate(input);
  if (!date) return '';
  return date.toLocaleString(locale, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}
