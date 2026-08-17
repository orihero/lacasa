/**
 * ApplicationsScreen — the realtor application review queue, and the highest
 * stakes screen in the control room: confirming Approve here promotes a
 * stranger's account from Buyer to Agent, which is the only path to an agent
 * account that exists.
 *
 * A TABLE, NOT THE MOCKUP'S REVIEW CARDS. mockups/build/web-admin.src.html's
 * `#x-apps` draws three tall `.qc` cards, which works at three applications
 * and stops working at thirty: an admin clearing a queue is comparing rows
 * (this one is an agency of 16+ with no office phone; that one is solo), and
 * comparison is what a 38px dense row is for and what a stack of cards
 * prevents. Every field the card showed is still here, one per column.
 *
 * THE ROW ACTIONS ONLY EXIST ON THE PENDING TAB. The decision endpoints accept
 * a PENDING row and nothing else — an Approve button on an already-approved
 * row could only ever produce a 409. Rather than render a control that is
 * guaranteed to fail, the last column carries the decision timestamp on the
 * approved and rejected tabs, which is the fact those tabs are actually read
 * for.
 *
 * THE 409 IS NOT AN ERROR STATE. `not_pending` means another admin decided
 * this application first — the decision the local queue was based on, not the
 * one being made. So it closes the dialog, says so plainly in a neutral banner
 * and refetches (the invalidation lives in useDecideApplication's onError),
 * rather than painting a red failure over a control room that is working
 * exactly as designed.
 */
import { useState } from "react";
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
import { CheckIcon, UsersThreeIcon, XIcon } from "@/ui/icons";
import { EM_DASH, formatDate, formatDateTime } from "@/lib/format";
import { REALTOR_KIND_LABEL, REALTOR_KIND_TONE, TEAM_SIZE_LABEL } from "@/lib/labels";
import type { ApplicationsStatusFilter } from "@/data/queryKeys";
import {
  flattenApplicationPages,
  isApplicationAlreadyDecided,
  useApplications,
  useDecideApplication,
  type ApplicationDecision,
} from "@/data/useApplications";
import { DecisionDialog } from "./DecisionDialog";
import { InlineBanner } from "./InlineBanner";

const STATUS_OPTIONS: ReadonlyArray<SegOption<ApplicationsStatusFilter>> = [
  { value: "pending", label: "Pending" },
  { value: "approved", label: "Approved" },
  { value: "rejected", label: "Rejected" },
];

/**
 * No counts on the segments, though the mockup shows "Pending 3". The three
 * numbers exist (GET /admin/overview's `applications` block) but this screen
 * does not read that endpoint, and a count assembled from "how many rows have
 * I paged in so far" would be a different number wearing the same label. An
 * admin deciding whether the queue is clear must not be shown an invented
 * figure — the rail's badge, which subscribes to the real overview cache
 * entry, is where that count belongs.
 */

/**
 * "No rows" means something different on each tab, which is exactly the
 * ambiguity EmptyState's `sub` exists to resolve: an empty pending queue is
 * good news, an empty rejected list is a fact about history.
 */
const EMPTY_COPY: Record<ApplicationsStatusFilter, { title: string; sub: string }> = {
  pending: {
    title: "The queue is clear",
    sub: "No realtor application is waiting on a decision.",
  },
  approved: {
    title: "No approved applications",
    sub: "Nobody has been granted agent access through this queue yet.",
  },
  rejected: {
    title: "No rejected applications",
    sub: "No application has been turned down yet.",
  },
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
  // Filter state is local rather than in the URL. A search-param-backed filter
  // would be nicer to share, but this app's tests cannot mount a real router
  // (see src/test/render.tsx), and a filter that survives a page refresh is
  // not worth making the highest-stakes screen the only one that is untestable
  // end to end.
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
          // retrying would 409 again. Close it and explain, and let the
          // refetch the hook already triggered replace the row.
          if (!isApplicationAlreadyDecided(error)) return;
          setStale({ fullName: pending.application.fullName });
          setPending(null);
        },
      },
    );
  }

  function changeStatus(next: ApplicationsStatusFilter) {
    setStatus(next);
    // The banner is about one row on the tab that was being looked at; carrying
    // it across to a different list would leave a sentence with no referent.
    setStale(null);
  }

  const dialogError =
    decide.isError && !isApplicationAlreadyDecided(decide.error) ? decide.error.message : null;

  return (
    <>
      {/* The mockup's `.warn`, and the one piece of it that is load-bearing
          rather than decorative. Shown only on the pending tab: on the other
          two there is nothing to approve, and a permanent warning stops being
          read long before it stops being displayed. */}
      {isPendingTab ? (
        <Notice title="Approving promotes the account's role from Buyer to Agent.">
          This is the only path to an agent account — a realtor status is an application, not a
          permission. Approving records the decision and cannot be silently undone; demoting the
          account later leaves their listings behind.
        </Notice>
      ) : null}

      <PageHead
        // The endpoint's keyset order is (createdAt desc, id desc) on the
        // ACCOUNT, so this list is newest signup first — not oldest
        // application first, which is what the mockup's caption claims and
        // what a review queue would ideally be sorted by. There is no
        // parameter to ask for another order, so the honest thing is to say
        // which one this is rather than to imply a triage order the server
        // does not provide.
        note="Newest accounts first"
      >
        <Seg
          label="Application status"
          options={STATUS_OPTIONS}
          value={status}
          // Amber on the selected segment only while it is the queue with work
          // in it; Approved and Rejected are archives, not to-do lists.
          hot={isPendingTab}
          onChange={changeStatus}
        />
      </PageHead>

      {stale ? (
        <InlineBanner onDismiss={() => setStale(null)}>
          <b className="font-semibold text-ink">{stale.fullName}</b>&rsquo;s application was already
          decided by another admin, so nothing was changed. The queue has been refreshed.
        </InlineBanner>
      ) : null}

      {/* A refetch that fails once the table is already populated must not
          replace it: the rows on screen are still the rows the server last
          sent, and blanking them would lose an admin's place in a queue they
          are working through. The full ErrorState is reserved for the case
          where there is genuinely nothing to show. */}
      {query.isError && rows.length > 0 ? (
        <InlineBanner tone="error">
          Could not refresh the list: {query.error.message}. The rows below are from the last
          successful load.
        </InlineBanner>
      ) : null}

      <Panel>
        {query.isError && rows.length === 0 ? (
          <ErrorState error={query.error} onRetry={() => void query.refetch()} />
        ) : query.isPending ? (
          <Table>
            <ApplicationsHead isPendingTab={isPendingTab} />
            <TableSkeleton rows={6} cols={6} />
          </Table>
        ) : rows.length === 0 ? (
          <EmptyState
            icon={UsersThreeIcon}
            title={EMPTY_COPY[status].title}
            sub={EMPTY_COPY[status].sub}
          />
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
              hasMore={Boolean(query.hasNextPage)}
              isFetching={query.isFetchingNextPage}
              onLoadMore={() => void query.fetchNextPage()}
              noun="applications"
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
          onCancel={() => setPending(null)}
        />
      ) : null}
    </>
  );
}

/**
 * Shared by the skeleton and the loaded table so the two cannot drift into
 * different column counts mid-load, which reads as the table jumping.
 */
function ApplicationsHead({ isPendingTab }: { isPendingTab: boolean }) {
  return (
    <THead>
      <TR>
        <TH width="26%">Applicant</TH>
        <TH width="10%">Kind</TH>
        <TH width="20%">Agency name</TH>
        <TH width="10%">Team size</TH>
        <TH width="18%">Applied</TH>
        <TH align="right">{isPendingTab ? "" : "Decided"}</TH>
      </TR>
    </THead>
  );
}

/**
 * A value the applicant did not supply renders as the one no-value glyph in
 * the faintest ink, never as an empty cell and never as a fabricated blank
 * string: "no agency name" is a real and meaningful answer on a solo
 * application, and it has to be visibly distinct from a column that failed to
 * render. `title` carries the longer reason when there is one worth hovering
 * for — a row with no application block at all needs to explain itself.
 */
function Blank({ title }: { title?: string }) {
  return (
    <span className="text-faint" title={title}>
      {EM_DASH}
    </span>
  );
}

/**
 * The wire is nullable here and the contract is not: @lacasa/api-client types
 * `AdminApplicationRow.realtor` as a non-null RealtorProfile ("a row without
 * an application is filtered out before it reaches this list"), but the
 * endpoint filters on `realtorStatus` ALONE while serializeUser.js returns
 * `realtor: null` for any row whose `realtorKind` was never set — and those
 * two columns are independent. adminService.serializeApplicationRow says so in
 * its own comment, and a seeded database proves it: apps/api/prisma/seed.js
 * creates agent@lacasa.dev with no kind, seed-olx.js then upserts its status
 * to APPROVED, and `GET /admin/applications?status=approved` answers with
 * `realtor: null` for that row today.
 *
 * Reading `.kind` straight off it threw a TypeError mid-render, and nothing
 * above this row is an error boundary, so the whole control room went blank on
 * a tab that is only being read. Widening the type locally is the honest fix
 * available from this side of the contract: the row still renders, and every
 * field it cannot vouch for says so instead of being invented.
 */
function realtorOf(application: AdminApplicationRow): RealtorProfile | null {
  return application.realtor ?? null;
}

/** Hover text for every cell of a row whose application block never arrived. */
const NO_APPLICATION_TITLE =
  "This account carries a realtor status but no application details — nothing was recorded when the status was set.";

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
  const realtor = realtorOf(application);

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
          <Tag tone={REALTOR_KIND_TONE[realtor.kind]}>{REALTOR_KIND_LABEL[realtor.kind]}</Tag>
        ) : (
          <Blank title={NO_APPLICATION_TITLE} />
        )}
      </TD>
      <TD>{realtor?.agencyName ?? <Blank title={realtor ? undefined : NO_APPLICATION_TITLE} />}</TD>
      <TD>
        {realtor?.teamSize ? (
          TEAM_SIZE_LABEL[realtor.teamSize]
        ) : (
          <Blank title={realtor ? undefined : NO_APPLICATION_TITLE} />
        )}
      </TD>
      {/* The full timestamp, not a date: two applications from the same day is
          the ordinary case on this queue, and the time is what tells them
          apart when one is being cross-referenced against a support thread. */}
      <TD mono>
        {realtor?.appliedAt ? (
          formatDateTime(realtor.appliedAt)
        ) : (
          <Blank title={realtor ? undefined : NO_APPLICATION_TITLE} />
        )}
      </TD>
      <TD align="right" mono={!isPendingTab}>
        {isPendingTab ? (
          <RowActions>
            <RowAction
              icon={CheckIcon}
              // The visible text says "Approve" but the accessible name says
              // who it approves: a screen reader user tabbing a 25-row queue
              // hears twenty-five identical "Approve" buttons otherwise.
              label={`Approve ${application.fullName}`}
              tone="ok"
              disabled={busy}
              onClick={() => onDecide(application, "approve")}
            >
              Approve
            </RowAction>
            <RowAction
              icon={XIcon}
              label={`Reject ${application.fullName}`}
              tone="no"
              disabled={busy}
              onClick={() => onDecide(application, "reject")}
            >
              Reject
            </RowAction>
          </RowActions>
        ) : realtor?.decidedAt ? (
          formatDate(realtor.decidedAt)
        ) : (
          <Blank title={realtor ? undefined : NO_APPLICATION_TITLE} />
        )}
      </TD>
    </TR>
  );
}
