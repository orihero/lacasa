/**
 * @lacasa/api-client/resources/admin — the control-room endpoints under
 * /api/admin, consumed by apps/admin.
 *
 * Unlike every other module here this one ports nothing: there is no
 * apps/web store behind it. Server-side the whole prefix sits behind
 * requireAuth + requireRole("ADMIN"), so a caller wired with a non-admin
 * token gets a 403 out of the Transport rather than an empty list — the
 * admin app must gate its own routes on `user.role === "admin"` too, and
 * not lean on these calls failing quietly.
 *
 * ADMIN is a *wider* role than agent, not a superset of it (see
 * effectiveAgentId() in apps/api/src/middleware/roles.js): nothing in this
 * resource is agent-scoped, and every list below reads across all agents.
 *
 * Pagination is keyset, not offset: every list is ordered (createdAt desc,
 * id desc) and the server hands back an opaque `nextCursor` that the caller
 * passes straight back as `cursor`. Never construct or parse one — it is
 * the last item's id today, and that is deliberately not part of the
 * contract. `nextCursor: null` means the page just returned was the last.
 */
import type { LeadStatusKey, RealtorStatusKey, UserRoleKey } from '@lacasa/domain';
import type { ApiClient } from '../core/client';
import type { AuthUser, RealtorProfile } from './auth';

/** The envelope every paged admin list comes back in. */
export interface AdminPage<T> {
  items: T[];
  nextCursor: string | null;
}

/**
 * Paging params shared by every list call. Both are optional: the server
 * defaults `limit` to 25 and caps it at 100, and an absent `cursor` means
 * the first page.
 */
export interface AdminPageParams {
  limit?: number;
  cursor?: string;
}

/**
 * Counts of publications by PublishStatus, lowercased onto the wire like
 * every other enum in this codebase. Written out rather than derived from a
 * @lacasa/domain map because there isn't one — src/enums/publish.ts owns the
 * channel vocabulary (ALL_CHANNELS) but not the status vocabulary, which
 * lives only in the Prisma `PublishStatus` enum. If a PUBLISH_STATUS map is
 * ever added there, this should become Record<PublishStatusKey, number>.
 */
export interface AdminPublicationCounts {
  published: number;
  failed: number;
  pending: number;
  /** Extension-assisted: the form was filled but no human has hit Publish yet. */
  drafted_awaiting_review: number;
}

/** One row of the overview's "newest accounts" strip — five at most. */
export interface AdminRecentSignup {
  id: string;
  fullName: string;
  email: string;
  role: UserRoleKey;
  createdAt: string;
}

export interface AdminOverview {
  /** `buyers` counts role USER; the four buckets sum to `total`. */
  users: { total: number; buyers: number; agents: number; coworkers: number; admins: number };
  /**
   * Realtor applications by status. `none` (the buyer default) is absent on
   * purpose: it is the state of *not* having applied, not a fourth bucket.
   */
  applications: { pending: number; approved: number; rejected: number };
  ads: { total: number; active: number; sold: number; draft: number };
  leads: { total: number; byStatus: Record<LeadStatusKey, number> };
  publications: AdminPublicationCounts;
  recentSignups: AdminRecentSignup[];
}

/**
 * The three application states an admin can filter on. `none` is excluded
 * because the endpoint only ever returns rows with realtorStatus != NONE —
 * asking for it could only ever return an empty page.
 */
export type AdminApplicationStatus = Exclude<RealtorStatusKey, 'none'>;

export interface AdminApplicationRow {
  id: string;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  /**
   * Exactly what serializeUser.js puts on `user.realtor` — and NULLABLE here,
   * same as on AuthUser. It is tempting to narrow this to a non-null
   * RealtorProfile on the grounds that the endpoint only returns rows that
   * applied, but that is false and the false version shipped once already:
   * the list filters on `realtorStatus`, while serializeUser derives the whole
   * `realtor` object from `realtorKind` — two independent nullable columns
   * (see adminService.js's own note). A row with realtorStatus=APPROVED and
   * realtorKind=NULL is real and reachable from the standard seed, so the
   * narrowed type turned a rendering decision into an unguarded dereference
   * that took the whole control room down on the Approved tab.
   */
  realtor: RealtorProfile | null;
  createdAt: string;
}

export interface AdminListApplicationsParams extends AdminPageParams {
  /** Defaults to `pending` server-side when omitted — the review queue. */
  status?: AdminApplicationStatus;
}

/**
 * What approve/reject return: the plain serializeUser shape, not an
 * AdminUserRow. The decision endpoints touch one account and report it back;
 * they do not go count its ads and leads.
 */
export interface AdminApplicationDecisionResponse {
  user: AuthUser;
}

/**
 * Ads owned and leads held by one account. Both are honest raw counts — a
 * demoted agent keeps whatever it owned, because nothing is cascade-deleted
 * on a role change.
 */
export interface AdminUserCounts {
  ads: number;
  leads: number;
}

/**
 * The serializeUser shape plus the two facts the admin list needs. `role` is
 * narrowed to UserRoleKey here (AuthUser leaves it a bare `string` for
 * callers that only ever display it) because the users screen branches on
 * it and PATCH .../role only accepts these four keys.
 */
export interface AdminUserRow extends AuthUser {
  role: UserRoleKey;
  createdAt: string;
  counts: AdminUserCounts;
}

export interface AdminUserResponse {
  user: AdminUserRow;
}

export interface AdminListUsersParams extends AdminPageParams {
  /** Case-insensitive "contains" over fullName OR email. */
  q?: string;
  role?: UserRoleKey;
  realtorStatus?: RealtorStatusKey;
}

/**
 * ActivityEvent.type, lowercased onto the wire. Written out for the same
 * reason as AdminPublicationCounts: @lacasa/domain's EVENT_STAGE covers only
 * the five legacy Firestore stages (and maps SCREAMING_SNAKE keys to
 * numbers, not to wire strings), while the Prisma `EventType` enum has grown
 * six more for the extension-assisted crosspost sessions.
 */
export type AdminAuditEventType =
  | 'ad_created'
  | 'ad_sold'
  | 'ad_draft_updated'
  | 'lead_created'
  | 'lead_status_changed'
  | 'olx_crosspost_started'
  | 'olx_crosspost_completed'
  | 'olx_crosspost_aborted'
  | 'ig_assist_started'
  | 'ig_assist_completed'
  | 'ig_assist_aborted';

export interface AdminAuditRow {
  id: string;
  type: AdminAuditEventType;
  createdAt: string;
  agent: { id: string; fullName: string } | null;
  coworker: { id: string; fullName: string } | null;
  /** Null once the ad is deleted — ActivityEvent.adId is ON DELETE SET NULL. */
  ad: { id: string; title: string } | null;
  lead: { id: string; fullName: string } | null;
  /**
   * ActivityEvent.meta, a free-form Json column whose shape depends on
   * `type`. `unknown` rather than a record: the caller has to narrow it,
   * which is the truthful cost of reading an untyped column.
   */
  meta: unknown;
}

export interface AdminListAuditParams extends AdminPageParams {
  type?: AdminAuditEventType;
  agentId?: string;
}

export function createAdminResource(client: ApiClient) {
  return {
    overview() {
      return client.request<AdminOverview>({ method: 'GET', path: '/admin/overview' });
    },

    /**
     * Absent params are passed as `undefined` rather than being stripped
     * here — QueryParams allows undefined precisely so every Transport drops
     * those keys itself (apps/console's buildUrl skips them, apps/web's
     * axios does the same). Sending `?status=` instead would mean "the empty
     * status", not "no filter".
     */
    listApplications(params: AdminListApplicationsParams = {}) {
      return client.request<AdminPage<AdminApplicationRow>>({
        method: 'GET',
        path: '/admin/applications',
        query: { status: params.status, limit: params.limit, cursor: params.cursor },
      });
    },

    /**
     * Approves the application AND promotes role USER -> AGENT. A 409
     * `not_pending` means someone else already decided this one — refetch
     * the queue rather than retrying.
     */
    approveApplication(userId: string) {
      return client.request<AdminApplicationDecisionResponse>({
        method: 'POST',
        path: `/admin/applications/${userId}/approve`,
      });
    },

    /** Rejects the application and leaves `role` alone. 409 `not_pending` as above. */
    rejectApplication(userId: string) {
      return client.request<AdminApplicationDecisionResponse>({
        method: 'POST',
        path: `/admin/applications/${userId}/reject`,
      });
    },

    listUsers(params: AdminListUsersParams = {}) {
      return client.request<AdminPage<AdminUserRow>>({
        method: 'GET',
        path: '/admin/users',
        query: {
          q: params.q,
          role: params.role,
          realtorStatus: params.realtorStatus,
          limit: params.limit,
          cursor: params.cursor,
        },
      });
    },

    getUser(id: string) {
      return client.request<AdminUserResponse>({ method: 'GET', path: `/admin/users/${id}` });
    },

    /**
     * The guard rails are server-side and each has its own error code, so
     * the UI can say what actually went wrong: `self_demotion` (400),
     * `last_admin` (409), `coworker_needs_agent` (400). Demoting an agent
     * that still owns ads or coworkers succeeds — nothing is cascaded.
     */
    setUserRole(id: string, role: UserRoleKey) {
      return client.request<AdminUserResponse>({
        method: 'PATCH',
        path: `/admin/users/${id}/role`,
        body: { role },
      });
    },

    listAudit(params: AdminListAuditParams = {}) {
      return client.request<AdminPage<AdminAuditRow>>({
        method: 'GET',
        path: '/admin/audit',
        query: {
          type: params.type,
          agentId: params.agentId,
          limit: params.limit,
          cursor: params.cursor,
        },
      });
    },
  };
}

export type AdminResource = ReturnType<typeof createAdminResource>;
