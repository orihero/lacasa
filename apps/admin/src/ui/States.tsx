/**
 * States — loading / empty / error / table skeleton, plus the amber `Notice`
 * banner the mockup uses to explain a consequence before an admin acts.
 *
 * ErrorState surfaces the REAL error message rather than a generic
 * "something went wrong". This is an internal operations tool: a swallowed
 * error on the screen that approves accounts costs someone their afternoon,
 * and an admin is exactly the person who can act on "409 not_pending".
 * `error` is typed `unknown` (not `Error`) because it is whatever a
 * react-query hook's `.error` holds — a real `Error`, @lacasa/domain's
 * `ApiError`, or in the worst case something a non-fetch failure threw; the
 * extraction below degrades through all three rather than assuming a shape.
 *
 * EmptyState takes `title` AND `sub` because "no rows" is ambiguous on a
 * filtered surface: an empty applications queue ("nothing is waiting on
 * you") and an empty filter result ("no rejected applications in the last 30
 * days") are opposite facts that look identical without the second line.
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import { Button } from "./Button";
import type { IconComponent } from "./icons";
import { InfoIcon, WarningCircleIcon } from "./icons";
import { TBody, TD, TR } from "./Table";

export function LoadingState({ label = "Loading…" }: { label?: string }) {
  return (
    <div
      role="status"
      className="flex flex-col items-center justify-center gap-3 py-16 text-muted"
    >
      <span
        aria-hidden="true"
        className="h-5 w-5 animate-spin rounded-full border-2 border-line border-t-acc"
      />
      <span className="text-small">{label}</span>
    </div>
  );
}

export function EmptyState({
  icon: Icon,
  title,
  sub,
  action,
}: {
  icon?: IconComponent;
  title: ReactNode;
  sub?: ReactNode;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 py-16 text-center">
      {Icon ? (
        <span className="mb-1 grid h-11 w-11 place-items-center rounded-panel border border-line bg-sunk text-muted">
          <Icon size={20} />
        </span>
      ) : null}
      <div className="text-lg font-semibold text-ink">{title}</div>
      {sub != null ? <div className="max-w-sm text-small text-muted">{sub}</div> : null}
      {action != null ? <div className="mt-2">{action}</div> : null}
    </div>
  );
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (typeof error === "string") return error;
  if (
    typeof error === "object" &&
    error !== null &&
    "message" in error &&
    typeof (error as { message: unknown }).message === "string"
  ) {
    return (error as { message: string }).message;
  }
  return "Something went wrong.";
}

/**
 * The API's `{ error: { code, message } }` code, when the thrown value
 * carries one. Shown next to the message in monospace because an admin
 * reading "not_pending" can act on it (someone else already decided this
 * application) where the prose alone is just a wall.
 */
function errorCode(error: unknown): string | null {
  if (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    typeof (error as { code: unknown }).code === "string"
  ) {
    return (error as { code: string }).code;
  }
  return null;
}

export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  const code = errorCode(error);
  return (
    <div role="alert" className="flex flex-col items-center justify-center gap-2.5 py-16 text-center">
      <span className="grid h-11 w-11 place-items-center rounded-panel bg-err-soft text-err">
        <WarningCircleIcon size={20} />
      </span>
      <div className="text-lg font-semibold text-ink">Something went wrong</div>
      <p className="max-w-md text-small text-ink-2">{errorMessage(error)}</p>
      {code ? <p className="font-mono text-record text-muted">{code}</p> : null}
      {onRetry ? (
        <Button onClick={onRetry} className="mt-1">
          Try again
        </Button>
      ) : null}
    </div>
  );
}

/**
 * Renders as a `<tbody>` so it drops straight into `<Table><THead>…</THead>
 * <TableSkeleton /></Table>` while rows are loading, keeping the same column
 * rhythm and 38px row height the loaded table will snap into.
 */
export function TableSkeleton({ rows = 6, cols = 5 }: { rows?: number; cols?: number }) {
  return (
    <TBody>
      {Array.from({ length: rows }, (_, r) => (
        <TR key={r}>
          {Array.from({ length: cols }, (_, c) => (
            <TD key={c}>
              <span
                aria-hidden="true"
                className={clsx(
                  "block h-2.5 animate-pulse rounded-full bg-sunk",
                  c === 0 ? "max-w-[170px]" : "max-w-[80px]",
                )}
              />
            </TD>
          ))}
        </TR>
      ))}
    </TBody>
  );
}

/**
 * Notice — the mockup's `.warn` banner. Amber by default, magenta when the
 * thing being explained is irreversible. Used to state a CONSEQUENCE above
 * the controls that cause it ("approving promotes this account from USER to
 * AGENT and cannot be silently undone"), which is the one piece of the
 * mockup that is load-bearing rather than decorative: the admin reading it is
 * about to change someone else's account.
 */
export function Notice({
  tone = "acc",
  title,
  children,
}: {
  tone?: "acc" | "danger";
  title: ReactNode;
  children?: ReactNode;
}) {
  const accent = tone === "danger";
  return (
    <div
      className={clsx(
        "mb-3.5 flex items-start gap-2.5 rounded-panel border px-3 py-2.5",
        accent ? "border-danger bg-danger-soft" : "border-acc-line bg-acc-soft",
      )}
    >
      {accent ? (
        <WarningCircleIcon size={16} className="mt-px flex-none text-danger" />
      ) : (
        <InfoIcon size={16} className="mt-px flex-none text-acc" />
      )}
      <div className="min-w-0">
        <b className="block text-small font-bold text-ink">{title}</b>
        {children != null ? (
          <div className="mt-0.5 text-record leading-relaxed text-ink-2">{children}</div>
        ) : null}
      </div>
    </div>
  );
}
