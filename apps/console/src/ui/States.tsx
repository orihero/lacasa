/**
 * States — loading/empty/error/skeleton, F has no precedent for any of
 * these (the prototype is a static mockup that never actually waits on a
 * network). Built fresh in the same flat, warm-grey language as everything
 * else here.
 *
 * ErrorState surfaces the *real* error message rather than a generic
 * "something went wrong" — this is an internal tool an agent uses all day;
 * a swallowed error costs them the afternoon figuring out what happened.
 * `error` is typed `unknown` (not `Error`) because it's whatever a
 * react-query hook's `.error` field holds, which — depending on how
 * `fetchTransport` (owned by the data agent) reconstructs a failed
 * response — may be a real `Error`, `@lacasa/domain`'s `ApiError`, or in
 * the worst case something a non-fetch failure threw; the extraction below
 * degrades through all three rather than assuming the shape.
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import { Button } from "./Button";
import type { IconComponent } from "./icons";
import { WarningIcon } from "./icons";
import { TBody, TD, TR } from "./Table";

export function LoadingState({ label = "Loading…" }: { label?: string }) {
  return (
    <div role="status" className="flex flex-col items-center justify-center gap-3 py-16 text-ink-2">
      <span
        aria-hidden="true"
        className="h-6 w-6 animate-spin rounded-full border-2 border-hairline border-t-ink"
      />
      <span className="text-body">{label}</span>
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
        <span className="mb-1 flex h-12 w-12 items-center justify-center rounded-full bg-surface-inner text-ink-2">
          <Icon size={22} />
        </span>
      ) : null}
      <div className="text-title font-semibold text-ink">{title}</div>
      {sub != null ? <div className="max-w-sm text-small text-ink-2">{sub}</div> : null}
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

export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  return (
    <div role="alert" className="flex flex-col items-center justify-center gap-3 py-16 text-center">
      <span className="flex h-12 w-12 items-center justify-center rounded-full bg-err-soft text-err">
        <WarningIcon size={22} />
      </span>
      <div className="text-title font-semibold text-ink">Something went wrong</div>
      <p className="max-w-sm text-small text-ink-2">{errorMessage(error)}</p>
      {onRetry ? (
        <Button variant="dark" onClick={onRetry} className="mt-1">
          Try again
        </Button>
      ) : null}
    </div>
  );
}

/**
 * Renders as a `<tbody>` so it drops straight into `<Table><THead>…</THead>
 * <TableSkeleton /></Table>` while real rows are loading, keeping the same
 * column rhythm (via `TD`) the loaded table will snap into.
 */
export function TableSkeleton({ rows = 5, cols = 5 }: { rows?: number; cols?: number }) {
  return (
    <TBody>
      {Array.from({ length: rows }, (_, r) => (
        <TR key={r}>
          {Array.from({ length: cols }, (_, c) => (
            <TD key={c}>
              <span
                aria-hidden="true"
                className={clsx(
                  "block h-3.5 animate-pulse rounded-full bg-surface-inner",
                  c === 0 ? "max-w-[180px]" : "max-w-[90px]",
                )}
              />
            </TD>
          ))}
        </TR>
      ))}
    </TBody>
  );
}
