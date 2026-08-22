/**
 * ApplicationsScreen — the realtor application review queue, and the highest
 * stakes screen in the control room: confirming Approve here promotes a
 * stranger's account from Buyer to Agent, which is the only path to an agent
 * account that exists on the platform.
 *
 * A TABLE, NOT REVIEW CARDS. The original mockup drew three tall review cards,
 * which works at three applications and fails at thirty: an admin clearing a
 * queue is COMPARING rows ("this one is an agency of 16+ with no office phone;
 * that one is solo"), and comparison is what a dense table row is for and what a
 * stack of cards prevents. Every field a card would have shown is a column.
 *
 * THE ROW ACTIONS EXIST ONLY ON THE PENDING TAB. The decision endpoints accept a
 * PENDING row and nothing else, so an Approve button on an already-approved row
 * could only ever produce a 409. Rather than render a control guaranteed to
 * fail, the last column carries the decision timestamp on the Approved and
 * Rejected tabs — which is the fact those tabs are actually read for.
 *
 * THE 409 IS NOT AN ERROR STATE. `not_pending` means another admin decided this
 * application first — the decision the local queue was based on was the thing
 * that was wrong, not the decision being made. So it closes the dialog, says so
 * plainly in a neutral `role="status"` banner and lets the refetch (already
 * triggered by the mutation's own onError) replace the row, rather than painting
 * a failure over a control room that is working exactly as designed.
 *
 * NO REFRESH CONTROL and NO PanelHead here, unlike Overview/Audit and Users:
 * both are deliberate absences (PRECEDENCE.md). A new control on the approvals
 * queue is not a free addition, and this panel has no title/sub pair to invent.
 * There are also no counts on the tabs — see the note above STATUS_OPTIONS.
 */
import { useState } from "react";
import { useTranslation } from "react-i18next";
import type { AdminApplicationRow, RealtorProfile } from "@lacasa/api-client";
import { PageHead } from "@/shell/PageHead";
import { Panel } from "@/ui/Panel";
import { Seg, type SegOption } from "@/ui/Seg";
import { Tag } from "@/ui/Tag";
import {
  CellMain,
  RowAction,
  RowActions,
  TBody,
  TD,
  TH,
  THead,
  TR,
  Table,
} from "@/ui/Table";
import { Avatar } from "@/ui/Avatar";
import { LoadMore } from "@/ui/LoadMore";
import { EmptyState, ErrorState, Notice, TableSkeleton } from "@/ui/States";
import { Check, Users, X } from "@/ui/icons";
import { EM_DASH, formatDate, formatDateTime } from "@/lib/format";
import { realtorKindLabel, realtorKindTone, teamSizeLabel } from "@/lib/labels";
import type { ApplicationsStatusFilter } from "@/lib/queryKeys";
import {
  flattenApplicationPages,
  isApplicationAlreadyDecided,
  useApplications,
  useDecideApplication,
  type ApplicationDecision,
} from "@/data/useApplications";
import { DecisionDialog } from "./DecisionDialog";
import { InlineBanner } from "./InlineBanner";
import "./applications.scss";

/**
 * NO COUNTS ON THE SEGMENTS, though the mockup shows "Pending 3". The three real
 * numbers exist — in `GET /admin/overview`'s `applications` block — but this
 * screen does not read that endpoint, and a count assembled from "how many rows
 * have I paged in so far" would be a different number wearing the same label. An
 * admin deciding whether the queue is clear must never be shown an invented
 * figure; the rail's badge, which subscribes to the real overview cache entry,
 * is where that count belongs.
 *
 * The three labels are the shared realtor-status vocabulary rather than three
 * new keys — "Pending"/"Approved"/"Rejected" are the same three words the Users
 * screen's status column shows, and one of them drifting would be a lie about
 * which filter is selected.
 */
const STATUS_OPTIONS: ReadonlyArray<ApplicationsStatusFilter> = [
  "pending",
  "approved",
  "rejected",
];

const STATUS_LABEL_KEY: Record<ApplicationsStatusFilter, string> = {
  pending: "realtorStatusPending",
  approved: "realtorStatusApproved",
  rejected: "realtorStatusRejected",
};

/**
 * "No rows" means something different on each tab, which is exactly the
 * ambiguity EmptyState's `sub` exists to resolve: an empty pending queue is GOOD
 * NEWS, an empty rejected list is a FACT ABOUT HISTORY. Those are opposite facts
 * that look identical without the second line.
 */
const EMPTY_COPY: Record<ApplicationsStatusFilter, { titleKey: string; subKey: string }> = {
  pending: { titleKey: "emptyQueueClearTitle", subKey: "emptyQueueClearSub" },
  approved: { titleKey: "emptyApprovedTitle", subKey: "emptyApprovedSub" },
  rejected: { titleKey: "emptyRejectedTitle", subKey: "emptyRejectedSub" },
};

interface PendingDecision {
  application: AdminApplicationRow;
  decision: ApplicationDecision;
}

/** What the banner says after a 409, kept out of the render for readability. */
interface StaleDecision {
  fullName: string;
}

export function ApplicationsScreen() {
  const { t } = useTranslation();

  // Filter state is local rather than in the URL. A search-param-backed filter
  // would be nicer to share and would survive a refresh; it is a legitimate
  // future improvement rather than something the reference implies exists, and
  // it is not being added blind on the screen that promotes accounts.
  const [status, setStatus] = useState<ApplicationsStatusFilter>("pending");
  const [pending, setPending] = useState<PendingDecision | null>(null);
  const [stale, setStale] = useState<StaleDecision | null>(null);

  const query = useApplications(status);
  const decide = useDecideApplication();

  const rows = flattenApplicationPages(query.data);
  const isPendingTab = status === "pending";

  function openDecision(application: AdminApplicationRow, decision: ApplicationDecision) {
    // Clears any error left over from a previous row's failed attempt, so the
    // dialog never opens already showing a message about somebody else.
    decide.reset();
    setStale(null);
    setPending({ application, decision });
  }

  function confirmDecision() {
    if (!pending) return;
    decide.mutate(
      { userId: pending.application.id, decision: pending.decision },
      {
        onSuccess: () => setPending(null),
        onError: (error) => {
          // The already-decided case leaves the dialog with nothing to offer:
          // retrying would 409 again. Close it and explain, and let the refetch
          // the mutation already triggered replace the row.
          if (!isApplicationAlreadyDecided(error)) return;
          setStale({ fullName: pending.application.fullName });
          setPending(null);
        },
      },
    );
  }

  function cancelDecision() {
    setPending(null);
    // Cancelling always resets the mutation, so a dialog reopened on another row
    // is clean. (PRECEDENCE.md unifies this with the role-change dialog, which
    // is the only one of the two that used to do it.)
    decide.reset();
  }

  function changeStatus(next: ApplicationsStatusFilter) {
    setStatus(next);
    // The banner is about one row on the tab that was being looked at; carrying
    // it across to a different list would leave a sentence with no referent.
    setStale(null);
  }

  // The 409 is answered by the banner, never inside the dialog. Every other
  // failure renders in the dialog verbatim, as an alert.
  const dialogError =
    decide.isError && !isApplicationAlreadyDecided(decide.error) ? decide.error.message : null;

  const empty = EMPTY_COPY[status];

  return (
    <>
      {/*
        The one piece of the mockup's warning banner that is load-bearing rather
        than decorative: the admin reading it is about to change someone else's
        account. Shown only on the pending tab — on the other two there is
        nothing to approve, and a permanent warning stops being read long before
        it stops being displayed. It is not dismissible.
      */}
      {isPendingTab ? (
        <Notice title={t("applicationsNoticeTitle")}>{t("applicationsNoticeBody")}</Notice>
      ) : null}

      <PageHead
        // The endpoint's keyset order is (createdAt desc, id desc) on the
        // ACCOUNT, so this list is newest signup first — not oldest application
        // first, which is what a triage queue would ideally want. There is no
        // parameter to ask for another order, so the honest thing is to state
        // which one this is rather than to imply one the server cannot provide.
        note={t("newestAccountsFirst")}
      >
        <Seg
          label={t("segApplicationStatus")}
          options={STATUS_OPTIONS.map(
            (value): SegOption<ApplicationsStatusFilter> => ({
              value,
              label: t(STATUS_LABEL_KEY[value]),
            }),
          )}
          value={status}
          // Emphasis on the selected segment only while it is the queue with
          // work in it; Approved and Rejected are archives, not to-do lists.
          hot={isPendingTab}
          onChange={changeStatus}
        />
      </PageHead>

      {stale ? (
        <InlineBanner onDismiss={() => setStale(null)}>
          <b className="applications__name">{stale.fullName}</b>
          {t("staleDecisionSuffix")}
        </InlineBanner>
      ) : null}

      {/*
        A refetch that fails once the table is already populated must NOT replace
        it: the rows on screen are still the rows the server last sent, and
        blanking them would lose an admin's place in a queue they are working
        through. No dismiss control — it has to stay put while the condition
        holds. The full ErrorState is reserved for the case where there is
        genuinely nothing to show.
      */}
      {query.isError && rows.length > 0 ? (
        <InlineBanner tone="error">
          {t("couldNotRefreshList", { message: query.error.message })}
        </InlineBanner>
      ) : null}

      <Panel>
        {query.isError && rows.length === 0 ? (
          <ErrorState error={query.error} onRetry={() => void query.refetch()} />
        ) : query.isPending ? (
          // Keyed on isPending, so CHANGING A TAB SHOWS THE SKELETON rather than
          // holding the previous tab's rows under the new tab's heading. Every
          // filter is its own cache entry and there is no
          // `placeholderData: keepPreviousData` — deliberately.
          <Table>
            <ApplicationsHead isPendingTab={isPendingTab} />
            <TableSkeleton rows={6} cols={6} />
          </Table>
        ) : rows.length === 0 ? (
          <EmptyState icon={Users} title={t(empty.titleKey)} sub={t(empty.subKey)} />
        ) : (
          <>
            <Table>
              <ApplicationsHead isPendingTab={isPendingTab} />
              <TBody>
                {rows.map((row) => (
                  <ApplicationRow
                    key={row.id}
                    application={row}
                    isPendingTab={isPendingTab}
                    // Only the row actually in flight is disabled. Freezing the
                    // whole table during one decision would stop an admin
                    // queueing up the next row they have already read.
                    busy={decide.isPending && decide.variables?.userId === row.id}
                    onDecide={openDecision}
                  />
                ))}
              </TBody>
            </Table>
            <LoadMore
              loaded={rows.length}
              // No `total`: the endpoint returns none, and "of ~100" inferred
              // from a page size would be a fabricated number on the screen
              // that decides who becomes an agent.
              hasMore={Boolean(query.hasNextPage)}
              isFetching={query.isFetchingNextPage}
              onLoadMore={() => void query.fetchNextPage()}
              noun={t("nounApplications")}
            />
          </>
        )}
      </Panel>

      {pending ? (
        <DecisionDialog
          application={pending.application}
          decision={pending.decision}
          busy={decide.isPending}
          error={dialogError}
          onConfirm={confirmDecision}
          onCancel={cancelDecision}
        />
      ) : null}
    </>
  );
}

/**
 * Shared by the skeleton and the loaded table so the two cannot drift into
 * different column counts mid-load, which reads as the table jumping.
 *
 * The last header is the EMPTY STRING on the pending tab — no label belongs
 * above a pair of action buttons — and "Decided" on the settled tabs, where the
 * same cell carries the decision date instead.
 */
function ApplicationsHead({ isPendingTab }: { isPendingTab: boolean }) {
  const { t } = useTranslation();
  return (
    <THead>
      <TR>
        <TH width="26%">{t("columnApplicant")}</TH>
        <TH width="10%">{t("columnKind")}</TH>
        <TH width="20%">{t("columnAgencyName")}</TH>
        <TH width="10%">{t("columnTeamSize")}</TH>
        <TH width="18%">{t("columnApplied")}</TH>
        <TH align="right">{isPendingTab ? "" : t("columnDecided")}</TH>
      </TR>
    </THead>
  );
}

/**
 * A value the applicant did not supply renders as the one no-value glyph in the
 * faintest ink — never an empty cell, never `N/A`, never a fabricated `0`. "No
 * agency name" is a real and meaningful answer on a solo application, and it has
 * to be visibly distinct from a column that failed to render. `title` carries
 * the longer reason when there is one worth hovering for; a row with no
 * application block at all needs to explain itself, and a row whose applicant
 * merely left a field blank does not.
 */
function Blank({ title }: { title?: string }) {
  return (
    <span className="applications__blank" title={title}>
      {EM_DASH}
    </span>
  );
}

/**
 * The wire is nullable here and the old contract was not. @lacasa/api-client once
 * typed `AdminApplicationRow.realtor` as a non-null RealtorProfile ("a row
 * without an application is filtered out before it reaches this list") — and
 * that is false, and the false version shipped and broke production. The
 * endpoint filters on `realtorStatus` ALONE, while the user serializer derives
 * the whole `realtor` object from `realtorKind`: two independent nullable
 * columns. A row with `realtorStatus = APPROVED` and `realtorKind = NULL` is
 * real and reachable from the standard seed (`prisma/seed.js` creates
 * agent@lacasa.dev with no kind; `seed-olx.js` upserts its status to APPROVED),
 * so `GET /admin/applications?status=approved` answers with `realtor: null` for
 * that row today.
 *
 * Reading `.kind` straight off it threw a TypeError mid-render and took the
 * whole control room blank on a tab that is only being READ. The api-client's
 * SOURCE has since been widened to `RealtorProfile | null`, but the `dist` this
 * workspace resolves is still built from the narrower declaration — so as far as
 * the compiler here is concerned the field is non-null, and `?? null` is the
 * honest widening available from this side of a frozen contract. The guard stays
 * either way: this is a runtime fact about the wire, not a type-checker opinion.
 * There is an ErrorBoundary above this screen now, and it does not excuse it.
 */
function realtorOf(application: AdminApplicationRow): RealtorProfile | null {
  return application.realtor ?? null;
}

function ApplicationRow({
  application,
  isPendingTab,
  busy,
  onDecide,
}: {
  application: AdminApplicationRow;
  isPendingTab: boolean;
  busy: boolean;
  onDecide: (application: AdminApplicationRow, decision: ApplicationDecision) => void;
}) {
  const { t } = useTranslation();
  const realtor = realtorOf(application);
  // Hover text for every cell of a row whose application block never arrived —
  // and for none of the cells of a row whose applicant simply left a field
  // blank. "The applicant left agency name empty" and "the payload carried no
  // application at all" are different facts, and only the second needs
  // explaining.
  const noApplication = realtor ? undefined : t("noApplicationDetails");

  return (
    <TR>
      <TD>
        <CellMain
          thumb={<Avatar name={application.fullName} round />}
          title={application.fullName}
          sub={application.email}
        />
      </TD>
      <TD>
        {realtor ? (
          // Neither Solo nor Agency is urgent. The mockup drew Agency in the
          // "waiting on you" accent; an agency application is not more urgent
          // than a solo one, it is a different shape, and the accent on this
          // surface belongs to the queue depth alone.
          <Tag tone={realtorKindTone(realtor.kind)}>{realtorKindLabel(t, realtor.kind)}</Tag>
        ) : (
          <Blank title={noApplication} />
        )}
      </TD>
      <TD>{realtor?.agencyName ?? <Blank title={noApplication} />}</TD>
      <TD>
        {realtor?.teamSize ? (
          teamSizeLabel(t, realtor.teamSize)
        ) : (
          <Blank title={noApplication} />
        )}
      </TD>
      {/*
        The full timestamp, not a date: two applications from the same day is the
        ordinary case on this queue, and the time is what tells them apart when a
        row is cross-referenced against a support thread. It reads
        `realtor.appliedAt`, NEVER the account's `createdAt` — the two can be
        months apart.
      */}
      <TD mono>
        {realtor?.appliedAt ? (
          formatDateTime(realtor.appliedAt)
        ) : (
          <Blank title={noApplication} />
        )}
      </TD>
      <TD align="right" mono={!isPendingTab}>
        {isPendingTab ? (
          <RowActions>
            <RowAction
              icon={Check}
              // The visible text says "Approve"; the accessible name says WHO it
              // approves. A screen-reader user tabbing a 25-row queue otherwise
              // hears twenty-five identical "Approve" buttons.
              label={t("approveNamed", { name: application.fullName })}
              tone="ok"
              disabled={busy}
              onClick={() => onDecide(application, "approve")}
            >
              {t("approve")}
            </RowAction>
            <RowAction
              icon={X}
              label={t("rejectNamed", { name: application.fullName })}
              tone="no"
              disabled={busy}
              onClick={() => onDecide(application, "reject")}
            >
              {t("reject")}
            </RowAction>
          </RowActions>
        ) : realtor?.decidedAt ? (
          // Date only: the time of day is noise once the decision is history.
          formatDate(realtor.decidedAt)
        ) : (
          <Blank title={noApplication} />
        )}
      </TD>
    </TR>
  );
}
