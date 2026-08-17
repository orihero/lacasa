/**
 * LoadMore — the pagination footer for every list on this surface.
 *
 * NOT numbered pages, and that is forced by the API rather than chosen: every
 * admin list is keyset-paged on `(createdAt desc, id desc)` with an opaque
 * `cursor` that is just the last row's id (see the endpoint contract). There
 * is no page count to render and no way to jump to page 7 — a numbered pager
 * would be a lie about what the server can do. What keyset paging buys in
 * exchange is that a row cannot be silently skipped when a new signup lands
 * mid-scroll, which on an approvals queue matters more than random access.
 *
 * The loaded count is always shown, even on the last page, because "24 rows"
 * with no more to fetch and "24 rows so far" are different facts and an admin
 * deciding whether a queue is empty needs to know which one they are looking
 * at. `total` is optional: most of these endpoints do not return one, and
 * this component will not invent "of ~100" from a page size.
 */
import { CaretDownIcon } from "./icons";
import { Button } from "./Button";

export function LoadMore({
  loaded,
  total,
  hasMore,
  isFetching,
  onLoadMore,
  noun = "records",
}: {
  loaded: number;
  /** Only pass one the server actually returned — never an estimate. */
  total?: number;
  hasMore: boolean;
  isFetching?: boolean;
  onLoadMore: () => void;
  noun?: string;
}) {
  return (
    <div className="flex items-center gap-3 border-t border-line px-[15px] py-2.5">
      <span className="text-tiny text-muted">
        <span className="font-mono text-record text-ink-2">{loaded}</span>
        {total !== undefined ? (
          <>
            {" / "}
            <span className="font-mono text-record text-ink-2">{total}</span>
          </>
        ) : null}{" "}
        {noun}
        {hasMore ? " loaded" : ""}
      </span>
      <div className="ml-auto">
        {hasMore ? (
          <Button icon={CaretDownIcon} onClick={onLoadMore} disabled={isFetching}>
            {isFetching ? "Loading…" : "Load more"}
          </Button>
        ) : (
          <span className="text-tiny text-faint">End of list</span>
        )}
      </div>
    </div>
  );
}
