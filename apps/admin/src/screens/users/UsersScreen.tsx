/**
 * screens/users/UsersScreen — the user directory: every account on the
 * platform, searchable, filterable by role and by realtor-application status,
 * with one write behind a confirmation (RoleChangeDialog).
 *
 * WHAT THIS SCREEN DELIBERATELY DOES NOT HAVE, all for the same reason — no
 * model backs it, and a control room that shows a number it cannot vouch for
 * is worse than one that shows nothing:
 *   · A "Plan" column and an "Any plan" filter. There is no billing or premium
 *     model in schema.prisma; the column would be a hard-coded "Free" on every
 *     row.
 *   · A per-row lock/suspend action. Nothing in the schema suspends an
 *     account, and PATCH .../role is the only write the admin API exposes for
 *     a user.
 *   · A "view user" action. `admin.getUser()` exists, but there is no detail
 *     route in routes.tsx for it to open, and a button that goes nowhere is a
 *     worse affordance than an absent one.
 *   · A sort control. Ordering is fixed at (createdAt desc, id desc) because
 *     keyset paging depends on it — hence the "Newest accounts first" note.
 *   · A Refresh control (PRECEDENCE.md). Applications and Users have none;
 *     Overview and Audit do.
 *
 * Everything the table does show is a field of AdminUserRow as the server
 * sent it. Nothing is derived, inferred or defaulted.
 */
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import type { AdminUserRow } from "@lacasa/api-client";
import type { RealtorStatusKey, UserRoleKey } from "@lacasa/domain";
import { PageHead } from "@/shell/PageHead";
import { Avatar } from "@/ui/Avatar";
import { SearchInput, Select } from "@/ui/Field";
import { LoadMore } from "@/ui/LoadMore";
import { Panel, PanelHead } from "@/ui/Panel";
import { Seg, type SegOption } from "@/ui/Seg";
import { EmptyState, ErrorState, TableSkeleton } from "@/ui/States";
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
import { Tag } from "@/ui/Tag";
import { UserCog, Users } from "@/ui/icons";
import { EM_DASH, formatCount, formatDate, shortId } from "@/lib/format";
import {
  REALTOR_STATUS_ORDER,
  USER_ROLE_ORDER,
  realtorStatusLabel,
  realtorStatusTone,
  userRoleLabel,
  userRoleTone,
} from "@/lib/labels";
import { useSetUserRole, useUsers } from "@/data/useUsers";
import { RoleChangeDialog } from "./RoleChangeDialog";
import "./users.scss";

/** The "no filter" sentinel for the two filters that are pick-one controls. */
const ANY = "all";

type RoleFilter = UserRoleKey | typeof ANY;
type StatusFilter = RealtorStatusKey | typeof ANY;

/**
 * 300ms. `q` is an unanchored, case-insensitive ILIKE over two columns of the
 * users table — the one query on this surface that gets more expensive the
 * shorter the term is — so firing it per keystroke would put the worst version
 * of it (a single letter, matching most of the table) in front of every useful
 * one. Long enough to swallow a burst of typing, short enough that a paused
 * admin does not notice waiting.
 *
 * The screen debounces the TRIMMED value, so typing a trailing space after a
 * settled term fires no new request.
 */
function useDebouncedValue<T>(value: T, delayMs: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
}

/**
 * The realtor application on a row, or null. `AdminUserRow.realtor` is null
 * whenever the account has no `realtorKind` — which is every buyer and every
 * coworker, but is NOT the same fact as "realtorStatus is NONE". So a null
 * here renders as an em dash rather than as the "None" tag: the payload
 * genuinely does not carry a status for this row, and printing one would be
 * this screen inventing it (lib/format's rule, applied to an enum instead of
 * a count). The realtorStatus FILTER is unaffected — that is evaluated
 * server-side against the column itself.
 */
function realtorStatusOf(user: AdminUserRow): string | null {
  return user.realtor?.status ?? null;
}

export function UsersScreen() {
  const { t } = useTranslation();

  const [search, setSearch] = useState("");
  const [role, setRole] = useState<RoleFilter>(ANY);
  const [realtorStatus, setRealtorStatus] = useState<StatusFilter>(ANY);
  const [target, setTarget] = useState<AdminUserRow | null>(null);

  const q = useDebouncedValue(search.trim(), 300);

  const query = useUsers({
    q: q || undefined,
    role: role === ANY ? undefined : role,
    realtorStatus: realtorStatus === ANY ? undefined : realtorStatus,
  });
  const setUserRole = useSetUserRole();

  const users = query.data?.pages.flatMap((page) => page.items) ?? [];
  const filtered = Boolean(q) || role !== ANY || realtorStatus !== ANY;

  // Derived from the label maps' key order rather than retyped, so a new role
  // or realtor-status member cannot appear in labels.ts and be silently
  // unfilterable here.
  const roleOptions: SegOption<RoleFilter>[] = [
    { value: ANY, label: t("filterAll") },
    ...USER_ROLE_ORDER.map(
      (key): SegOption<RoleFilter> => ({ value: key, label: userRoleLabel(t, key) }),
    ),
  ];

  /**
   * The one-line form of a failure, for the strip that sits under a table that
   * still has rows in it. ErrorState is what renders the code as well, and it
   * only appears when there is nothing else on the panel competing with it.
   */
  function listErrorText(error: unknown): string {
    if (error instanceof Error && error.message) return error.message;
    return t("requestDidNotComplete");
  }

  function openRoleChange(user: AdminUserRow) {
    // Clears a refusal left over from the previous row — a `last_admin`
    // message still on screen while a different account's dialog is open
    // would read as a refusal of THIS change.
    setUserRole.reset();
    setTarget(user);
  }

  function closeRoleChange() {
    setUserRole.reset();
    setTarget(null);
  }

  return (
    <>
      <PageHead
        note={
          // Stated because keyset pagination makes it structural rather than a
          // preference: the endpoint orders by (createdAt desc, id desc) and
          // there is no sort control that could change it.
          t("newestAccountsFirst")
        }
      >
        <Seg options={roleOptions} value={role} onChange={setRole} label={t("segRole")} />

        <SearchInput
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder={t("searchNameOrEmail")}
          aria-label={t("searchUsersAriaLabel")}
          // The server rejects a `q` over 200 characters (the same ceiling it
          // puts on fullName). Capping the input means a pasted wall of text
          // is a truncated search rather than a 400 the admin has to decode.
          maxLength={200}
          className="users-toolbar__search"
        />

        <div className="users-toolbar__status">
          <Select
            aria-label={t("realtorStatusAriaLabel")}
            value={realtorStatus}
            onChange={(event) => setRealtorStatus(event.target.value as StatusFilter)}
          >
            <option value={ANY}>{t("anyRealtorStatus")}</option>
            {REALTOR_STATUS_ORDER.map((status) => (
              <option key={status} value={status}>
                {realtorStatusLabel(t, status)}
              </option>
            ))}
          </Select>
        </div>
      </PageHead>

      <Panel>
        <PanelHead title={t("usersDirectoryTitle")} sub={t("usersDirectorySub")} />

        {/* The full-panel error is reserved for the case where there is
            genuinely nothing else to show. A failure with rows already on
            screen — a Load more that 500s, a background refetch that times out
            — keeps those rows: react-query hands back the last successful
            `data` alongside the error, they are still exactly what the server
            last sent, and replacing a 200-row directory an admin is halfway
            through scanning with a retry button loses their place for no gain.
            Same rule the applications queue and the audit log follow. */}
        {query.isError && users.length === 0 ? (
          <ErrorState error={query.error} onRetry={() => void query.refetch()} />
        ) : !query.isPending && users.length === 0 ? (
          // Three different facts, and they must not share one message: a
          // filtered-away directory and an empty database are opposites, and
          // they look identical without the second line.
          <EmptyState
            icon={Users}
            title={filtered ? t("emptyNoMatchTitle") : t("noAccountsYet")}
            sub={
              filtered
                ? q
                  ? t("emptyNoMatchQuerySub", { q })
                  : t("emptyNoMatchSub")
                : t("emptyFreshDatabaseSub")
            }
          />
        ) : (
          <>
            <Table>
              <THead>
                <TR>
                  <TH width="26%">{t("columnUser")}</TH>
                  <TH>{t("columnUuid")}</TH>
                  <TH>{t("columnRole")}</TH>
                  <TH>{t("columnRealtorStatus")}</TH>
                  <TH align="right">{t("columnAds")}</TH>
                  <TH align="right">{t("columnLeads")}</TH>
                  <TH>{t("columnJoined")}</TH>
                  <TH />
                </TR>
              </THead>

              {query.isPending ? (
                <TableSkeleton rows={8} cols={8} />
              ) : (
                <TBody>
                  {users.map((user) => {
                    const status = realtorStatusOf(user);
                    return (
                      <TR key={user.id}>
                        <TD>
                          <CellMain
                            thumb={<Avatar src={user.avatar} name={user.fullName} round />}
                            title={user.fullName}
                            sub={user.email}
                          />
                        </TD>
                        <TD mono>
                          {/* Truncated for scanning, full id in the tooltip —
                              and in the confirmation dialog, which is where an
                              exact match actually has to be made. */}
                          <span title={user.id} className="users-uuid">
                            {shortId(user.id)}
                          </span>
                        </TD>
                        <TD>
                          <Tag tone={userRoleTone(user.role)}>{userRoleLabel(t, user.role)}</Tag>
                        </TD>
                        <TD>
                          {status ? (
                            <Tag tone={realtorStatusTone(status)}>
                              {realtorStatusLabel(t, status)}
                            </Tag>
                          ) : (
                            <span className="users-blank">{EM_DASH}</span>
                          )}
                        </TD>
                        <TD align="right" mono>
                          {formatCount(user.counts?.ads)}
                        </TD>
                        <TD align="right" mono>
                          {formatCount(user.counts?.leads)}
                        </TD>
                        <TD mono>
                          <span className="users-joined">{formatDate(user.createdAt)}</span>
                        </TD>
                        <TD align="right">
                          <RowActions>
                            <RowAction
                              icon={UserCog}
                              // Named per row: four identical "Change role"
                              // buttons in a 50-row table are four buttons a
                              // screen-reader user cannot tell apart, on the
                              // one control here that changes someone's access.
                              label={t("changeRoleFor", { name: user.fullName })}
                              onClick={() => openRoleChange(user)}
                            >
                              {t("columnRole")}
                            </RowAction>
                          </RowActions>
                        </TD>
                      </TR>
                    );
                  })}
                </TBody>
              )}
            </Table>

            {/* The other half of that rule: the rows stay, and the failure is
                still stated. Without this line a failed Load more would look
                exactly like reaching the end of the directory. */}
            {query.isError ? (
              <div role="alert" className="users-error-strip">
                {t("couldNotReadDirectory", { message: listErrorText(query.error) })}
              </div>
            ) : null}

            {query.isPending ? null : (
              <LoadMore
                loaded={users.length}
                hasMore={Boolean(query.hasNextPage)}
                isFetching={query.isFetchingNextPage}
                onLoadMore={() => void query.fetchNextPage()}
                noun={t("nounAccounts")}
              />
            )}
          </>
        )}
      </Panel>

      {target ? (
        <RoleChangeDialog
          // Keyed by row so the picker and any refusal reset when a different
          // account's dialog is opened, rather than the previous row's
          // selection carrying over into it.
          key={target.id}
          user={target}
          busy={setUserRole.isPending}
          error={setUserRole.error}
          onConfirm={(nextRole) =>
            setUserRole.mutate(
              { id: target.id, role: nextRole },
              // Closed only on success. A refusal keeps the dialog open with
              // its reason attached, because every one of the server's guard
              // rails is something the admin can act on from right here.
              { onSuccess: () => setTarget(null) },
            )
          }
          onCancel={closeRoleChange}
        />
      ) : null}
    </>
  );
}
