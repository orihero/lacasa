/**
 * CoworkersScreen — mockups/f/PLAN.md §3.7 / f-console.src.html #a-coworkers.
 *
 * THE DATA-HONESTY TEST CASE for this build: the prototype's row reads "11
 * listings · 3 closed · active 2 days ago", but `Coworker` (from
 * @lacasa/api-client) is only `{ id, fullName, email, phoneNumber, avatar,
 * agentId }` — none of those three numbers live on it. Each is handled on
 * its own merits, not uniformly faked or uniformly hidden:
 *
 *  - LISTINGS   real, derived: `deriveCoworkerMetrics` (src/data/useCoworkers)
 *               counts `useMyAds()`'s own Ad[] by `ad.coworkerId`. Same list
 *               the My ads screen renders from — not a second fetch that
 *               could disagree with it.
 *  - LAST ACTIVE real, derived: the same helper's newest
 *               `CoworkerStatisticEvent.createdAt` for that coworker, off
 *               `useCoworkerStatistics()` (verified against
 *               apps/api/src/routes/statistics.js — GET /statistics/coworkers
 *               returns the agent's raw ActivityEvent rows with a
 *               `coworkerId`/`createdAt`, nothing pre-aggregated). No events
 *               for a coworker renders an em dash, never a fabricated
 *               "Today".
 *  - CLOSED     NOT derivable, full stop: it means "leads with
 *               `LeadStatus.SUCCESS`", and that status does not exist in
 *               Prisma yet (PLAN.md §4, Decision 6.4 — a proposed addition,
 *               not a bug in this screen). The column renders an em dash for
 *               every row and a `<Flag>` says why, instead of a
 *               `deriveCoworkerMetrics`-shaped helper that would have to
 *               invent a zero.
 *
 * Loading/error are tracked per source rather than collapsed into one
 * boolean: `coworkersQuery` gates the table itself (no coworkers, no rows to
 * show), but `adsQuery`/`statsQuery` only feed two of its columns — if either
 * is still loading or has failed, only Listings/Last active fall back to "…"
 * / "—" for that reason, the rest of a perfectly good coworkers table isn't
 * thrown away over a slower or flakier secondary request.
 */
import { useMemo, useState } from "react";
import type { Coworker } from "@lacasa/api-client";
import { useAuth } from "@/lib/auth";
import { useMyAds } from "@/data/useAds";
import { useCoworkerStatistics } from "@/data/useStatistics";
import {
  useCoworkers,
  useCreateCoworker,
  useDeleteCoworker,
  useUpdateCoworker,
  deriveCoworkerMetrics,
} from "@/data/useCoworkers";
import { formatRelativeTime } from "@/lib/format";
import { PageHead } from "@/shell/PageHead";
import { Toolbar } from "@/shell/Toolbar";
import { Panel } from "@/ui/Panel";
import { FilterChip } from "@/ui/FilterChip";
import { Flag } from "@/ui/Flag";
import { ErrorState, TableSkeleton } from "@/ui/States";
import { Table, THead, TH, TBody, TR, TD, CellMain, GhostRow } from "@/ui/Table";
import { Avatar } from "@/ui/Avatar";
import { RowActions } from "@/ui/RowActions";
import { NotePencilIcon, PlusIcon, TrashIcon, UserIcon } from "@/ui/icons";
import { CoworkerFormModal } from "./CoworkerFormModal";
import { DeleteCoworkerModal } from "./DeleteCoworkerModal";

const COLUMN_COUNT = 7;

type ModalState =
  | { kind: "create" }
  | { kind: "edit"; coworker: Coworker }
  | { kind: "delete"; coworker: Coworker }
  | null;

// f-console.src.html's own `.flag` copy names the exact missing enum member
// (see e.g. the Leads screen's "LeadStatus.SUCCESS is not in the Prisma enum
// yet") rather than a vague "coming soon" — matched here for the same reason:
// an agent reading this should be able to tell a developer exactly what's
// missing, not just that something is.
function ClosedColumnFlag() {
  return (
    <Flag>
      &quot;Closed&quot; isn&apos;t shown — it depends on a lead status (
      <span className="font-mono">LeadStatus.SUCCESS</span>) that isn&apos;t in the Prisma enum yet.
    </Flag>
  );
}

export function CoworkersScreen() {
  const { user } = useAuth();
  const coworkersQuery = useCoworkers();
  const adsQuery = useMyAds();
  const statsQuery = useCoworkerStatistics();

  const createCoworker = useCreateCoworker();
  const updateCoworker = useUpdateCoworker();
  const deleteCoworker = useDeleteCoworker();

  const [modal, setModal] = useState<ModalState>(null);

  const coworkers = coworkersQuery.data ?? [];

  // Depends on the queries' `.data` directly, not on the `?? []`-defaulted
  // locals — a fresh `[]` literal on every render with no data yet would
  // otherwise look like a changed dependency every time and defeat the memo.
  const metricsById = useMemo(() => {
    const rows = coworkersQuery.data ?? [];
    const ads = adsQuery.data ?? [];
    const events = statsQuery.data ?? [];
    const map = new Map<string, ReturnType<typeof deriveCoworkerMetrics>>();
    for (const coworker of rows) {
      map.set(coworker.id, deriveCoworkerMetrics(coworker.id, ads, events));
    }
    return map;
  }, [coworkersQuery.data, adsQuery.data, statsQuery.data]);

  function closeModal() {
    setModal(null);
  }

  return (
    <>
      <PageHead crumb="Console · Team" title="Coworkers" />

      <Toolbar>
        <FilterChip icon={(iconProps) => <UserIcon weight="fill" {...iconProps} />}>
          {user ? `Under ${user.fullName}` : "Your team"}
        </FilterChip>
      </Toolbar>

      <Panel>
        {coworkersQuery.isLoading ? (
          <Table>
            <THead>
              <tr>
                <TH>Coworker</TH>
                <TH>Email</TH>
                <TH>Phone</TH>
                <TH align="right">Listings</TH>
                <TH align="right">Closed</TH>
                <TH>Last active</TH>
                <TH />
              </tr>
            </THead>
            <TableSkeleton rows={2} cols={COLUMN_COUNT} />
          </Table>
        ) : coworkersQuery.isError ? (
          <ErrorState error={coworkersQuery.error} onRetry={() => void coworkersQuery.refetch()} />
        ) : (
          <>
            {coworkers.length === 0 ? (
              <p className="mb-3 text-small text-ink-2">No coworkers yet — add your first one below.</p>
            ) : null}
            <Table>
              <THead>
                <tr>
                  <TH>Coworker</TH>
                  <TH>Email</TH>
                  <TH>Phone</TH>
                  <TH align="right">Listings</TH>
                  <TH align="right">Closed</TH>
                  <TH>Last active</TH>
                  <TH />
                </tr>
              </THead>
              <TBody>
                {coworkers.map((coworker) => {
                  const metrics = metricsById.get(coworker.id);
                  return (
                    <TR key={coworker.id}>
                      <TD>
                        <CellMain
                          thumb={<Avatar src={coworker.avatar} name={coworker.fullName} size="md" />}
                          title={coworker.fullName}
                          sub="Coworker"
                        />
                      </TD>
                      <TD>
                        <span className="font-mono text-tiny text-ink-2">{coworker.email}</span>
                      </TD>
                      <TD>
                        <span className="font-mono text-tiny text-ink-2">{coworker.phoneNumber ?? "—"}</span>
                      </TD>
                      <TD align="right" className="font-mono">
                        {adsQuery.isLoading ? "…" : adsQuery.isError ? "—" : (metrics?.listingsCount ?? 0)}
                      </TD>
                      <TD align="right" className="font-mono text-ink-2">
                        —
                      </TD>
                      <TD>
                        {statsQuery.isLoading
                          ? "…"
                          : statsQuery.isError
                            ? "—"
                            : metrics?.lastActiveAt
                              ? formatRelativeTime(metrics.lastActiveAt)
                              : "—"}
                      </TD>
                      <TD align="right">
                        <RowActions
                          actions={[
                            {
                              icon: NotePencilIcon,
                              label: `Edit ${coworker.fullName}`,
                              onClick: () => setModal({ kind: "edit", coworker }),
                            },
                            {
                              icon: TrashIcon,
                              label: `Delete ${coworker.fullName}`,
                              tone: "danger",
                              onClick: () => setModal({ kind: "delete", coworker }),
                            },
                          ]}
                        />
                      </TD>
                    </TR>
                  );
                })}
                {/* The screen's one accent element (PLAN.md §1) — every other
                    CTA on this screen (the two modals' submit buttons) is
                    `dark`, on purpose, so the lime never appears twice. */}
                <GhostRow colSpan={COLUMN_COUNT} icon={PlusIcon} onClick={() => setModal({ kind: "create" })}>
                  Create coworker
                </GhostRow>
              </TBody>
            </Table>
            <ClosedColumnFlag />
          </>
        )}
      </Panel>

      {modal?.kind === "create" ? (
        <CoworkerFormModal
          mode="create"
          onClose={closeModal}
          isSubmitting={createCoworker.isPending}
          error={createCoworker.error}
          onSubmit={(input) => {
            createCoworker.mutate(input, { onSuccess: closeModal });
          }}
        />
      ) : null}

      {modal?.kind === "edit" ? (
        <CoworkerFormModal
          mode="edit"
          coworker={modal.coworker}
          onClose={closeModal}
          isSubmitting={updateCoworker.isPending}
          error={updateCoworker.error}
          onSubmit={(input) => {
            updateCoworker.mutate({ id: modal.coworker.id, input }, { onSuccess: closeModal });
          }}
        />
      ) : null}

      {modal?.kind === "delete" ? (
        <DeleteCoworkerModal
          coworker={modal.coworker}
          onClose={closeModal}
          isSubmitting={deleteCoworker.isPending}
          error={deleteCoworker.error}
          onConfirm={() => {
            deleteCoworker.mutate(modal.coworker.id, { onSuccess: closeModal });
          }}
        />
      ) : null}
    </>
  );
}
