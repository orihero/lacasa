/**
 * States — loading, empty, error, the table skeleton, and the Notice banner
 * that states a consequence above the controls that cause it.
 *
 * This whole file is the part of the rebuild that the design contract would
 * have deleted, and it is kept on purpose (PRECEDENCE.md, conflicts 2–4):
 *
 *  · apps/web has NO error UI — every store catch logs and sets an empty list,
 *    so a failed fetch is indistinguishable from an empty result. On a surface
 *    where an empty list means "nobody is waiting on you", that is the single
 *    most dangerous thing this rebuild could inherit. `ErrorState` therefore
 *    shows the server's REAL message, the raw code in monospace, and a retry.
 *  · apps/web's empty state is one centred row reading "Ads not found".
 *    `EmptyState` keeps a title AND a sub, because the second line is the
 *    entire information content: an empty queue ("nothing is waiting on you")
 *    and an empty filter result ("no rejected applications") are opposite facts
 *    that look identical without it.
 *  · apps/web has no skeletons. The three list screens have them, with row
 *    counts their tests assert (6×6 applications, 8×8 users, 8×5 audit), and
 *    they are built from MUI's `<Skeleton>` so they still read as web-family.
 *    The overview keeps the full-screen loading state instead — both documents
 *    agree there.
 *
 * `EmptyState` and `ErrorState` titles are plain `<div>`s, NOT headings: the
 * topbar owns the page's one `<h1>` and a panel head owns the `<h2>`, so a
 * not-found screen contains no heading below the topbar at all.
 */
import Skeleton from "@mui/material/Skeleton";
import type { ReactNode } from "react";
import { useTranslation } from "react-i18next";
import { Button } from "./Button";
import { CircleAlert, Info, TriangleAlert, type IconComponent } from "./icons";
import { TBody, TD, TR } from "./Table";
import "./states.scss";

export function LoadingState({ label }: { label?: string }) {
  const { t } = useTranslation();
  return (
    // `.loading` is apps/web's spinner host — the class every screen there uses
    // (given a real centring rule once, in index.scss). `role="status"` is
    // this app's addition, so a screen reader is told the page is working
    // rather than left on an empty region.
    <div className="loading state-loading" role="status">
      <span className="state-loading__spinner" aria-hidden="true" />
      <span className="state-loading__label">{label ?? t("loading")}</span>
    </div>
  );
}

export function EmptyState({
  icon: Icon,
  title,
  /** The line that says WHICH kind of empty this is. Almost always worth passing. */
  sub,
  action,
}: {
  icon?: IconComponent;
  title: ReactNode;
  sub?: ReactNode;
  action?: ReactNode;
}) {
  return (
    <div className="state-empty">
      {Icon ? (
        <span className="state-empty__icon">
          <Icon size={22} aria-hidden="true" />
        </span>
      ) : null}
      <div className="state-empty__title">{title}</div>
      {sub != null ? <div className="state-empty__sub">{sub}</div> : null}
      {action != null ? <div className="state-empty__action">{action}</div> : null}
    </div>
  );
}

/**
 * `error` is `unknown` because it is whatever a react-query hook's `.error`
 * holds: a real `Error`, the api-client's `ApiError`, or in the worst case
 * something a non-fetch failure threw. The extraction degrades through all
 * three rather than assuming a shape.
 */
function errorMessage(error: unknown, fallback: string): string {
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
  return fallback;
}

/**
 * The API's `{ error: { code, message } }` code, when the thrown value carries
 * one. Shown in monospace next to the prose because an admin reading
 * `not_pending` can act on it — someone else already decided this application —
 * where the sentence alone is a wall.
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
  const { t } = useTranslation();
  const code = errorCode(error);

  return (
    <div className="state-error" role="alert">
      <span className="state-error__icon">
        <CircleAlert size={22} aria-hidden="true" />
      </span>
      <div className="state-error__title">{t("somethingWentWrong")}</div>
      <p className="state-error__message">
        {errorMessage(error, t("somethingWentWrongFallback"))}
      </p>
      {code === null ? null : <p className="state-error__code">{code}</p>}
      {onRetry ? (
        <div className="state-error__action">
          <Button onClick={onRetry}>{t("tryAgain")}</Button>
        </div>
      ) : null}
    </div>
  );
}

/**
 * Renders as the table's `<tbody>`, so it drops straight into
 * `<Table><THead/><TableSkeleton/></Table>` and keeps the loaded table's column
 * rhythm and row height rather than collapsing the layout while it waits.
 *
 * The screens pass their own counts, and those counts are asserted by their
 * tests: applications 6×6, users 8×8, audit 8×5.
 */
export function TableSkeleton({ rows = 6, cols = 5 }: { rows?: number; cols?: number }) {
  return (
    <TBody>
      {Array.from({ length: rows }, (_row, rowIndex) => (
        <TR key={rowIndex}>
          {Array.from({ length: cols }, (_col, colIndex) => (
            <TD key={colIndex}>
              <Skeleton
                variant="text"
                aria-hidden="true"
                // The first column is the record itself (a name, a timestamp);
                // the rest are short values. Two widths are enough to stop the
                // placeholder reading as a solid block.
                width={colIndex === 0 ? 170 : 80}
                height={14}
              />
            </TD>
          ))}
        </TR>
      ))}
    </TBody>
  );
}

/**
 * Notice — a banner stating a CONSEQUENCE above the controls that cause it
 * ("approving promotes this account from Buyer to Agent and cannot be silently
 * undone"). Load-bearing rather than decorative: the admin reading it is about
 * to change someone else's account. `danger` when the thing being explained is
 * irreversible.
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
  const danger = tone === "danger";
  return (
    <div className={danger ? "notice notice--danger" : "notice"}>
      <span className="notice__icon">
        {danger ? (
          <TriangleAlert size={16} aria-hidden="true" />
        ) : (
          <Info size={16} aria-hidden="true" />
        )}
      </span>
      <div className="notice__text">
        <b className="notice__title">{title}</b>
        {children != null ? <div className="notice__body">{children}</div> : null}
      </div>
    </div>
  );
}
