/**
 * LoadMore — the pagination footer under every list on this surface.
 *
 * NOT numbered pages, and that is forced by the API rather than chosen: every
 * admin list is keyset-paged on `(createdAt desc, id desc)` behind an opaque
 * cursor that is just the last row's id. There is no page count and no way to
 * jump to page 7, so MUI's `TablePagination` — which apps/web uses on all three
 * of its tables — could only be rendered by inventing a total (PRECEDENCE.md,
 * conflict 1). What keyset paging buys in exchange is that a row cannot be
 * silently skipped when a new signup lands mid-scroll, which on an approvals
 * queue matters more than random access.
 *
 * THE LOADED COUNT IS ALWAYS SHOWN, even on the last page: "24 records" with
 * nothing left to fetch and "24 records loaded" with more behind it are
 * different facts, and an admin deciding whether a queue is empty needs to know
 * which one they are reading.
 *
 * `total` is optional and MUST NEVER BE INVENTED from a page size ("of ~100" is
 * forbidden). Pass only a total the server actually returned.
 */
import { useTranslation } from "react-i18next";
import { Button } from "./Button";
import { ChevronDown } from "./icons";
import "./loadMore.scss";

export function LoadMore({
  loaded,
  total,
  hasMore,
  isFetching,
  onLoadMore,
  noun,
}: {
  loaded: number;
  /** Only ever a total the server returned. */
  total?: number;
  hasMore: boolean;
  isFetching?: boolean;
  onLoadMore: () => void;
  /** "applications", "accounts", "events". Defaults to "records". */
  noun?: string;
}) {
  const { t } = useTranslation();

  return (
    <div className="load-more">
      <span className="load-more__count">
        <span className="load-more__value">{loaded}</span>
        {total === undefined ? null : (
          <>
            {" / "}
            <span className="load-more__value">{total}</span>
          </>
        )}{" "}
        {noun ?? t("nounRecords")}
        {hasMore ? ` ${t("loadedSuffix")}` : ""}
      </span>
      <div className="load-more__action">
        {hasMore ? (
          <Button icon={ChevronDown} onClick={onLoadMore} disabled={isFetching}>
            {isFetching ? t("loading") : t("loadMore")}
          </Button>
        ) : (
          <span className="load-more__end">{t("endOfList")}</span>
        )}
      </div>
    </div>
  );
}
