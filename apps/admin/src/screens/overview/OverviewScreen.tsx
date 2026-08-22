/**
 * src/screens/overview — the control room's landing screen: everything
 * `GET /api/admin/overview` knows about the platform, and nothing else.
 *
 * WHAT IS NOT HERE, AND WHY THAT IS THE POINT. The mockup's overview opens with
 * six KPI tiles (two of them "Premium agents" and "MRR"), a twelve-day listings
 * trend chart, and a Queues panel with rows for 3D tour review, reported
 * listings and expired Instagram tokens. There is no billing model, no plan
 * model, no tour model, no report model and no time-series endpoint behind any
 * of that. Every one of them is omitted outright rather than rendered as a
 * zero, a dash or a placeholder: on the screen an operator uses to judge the
 * health of the business, an invented "$740" is not a design detail, it is a
 * false statement — and a tile that renders "—" forever is a promise that the
 * number is coming. What survives is the five aggregates the schema actually
 * backs (users, applications, ads, leads, publications) plus the recent-signups
 * strip. A test pins that: the screen's whole text must not match
 * /mrr|premium|plan|tour|report/i.
 *
 * WHERE THE ACCENT GOES. Exactly two numbers here are things an admin can *do*
 * something about: applications waiting for a decision, and publications that
 * failed. Those two tiles carry the surface's one emphasis treatment and link
 * to the screen that acts on them; everything else — including the two
 * distribution panels, whose buckets do have tones in @/lib/labels — is calm
 * neutral ink. That is the whole reason a pending count is scannable from
 * across a desk.
 *
 * NO FILTERS, NO TABS, NO SEARCH, NO SORT, NO PAGING, NO WRITES. The endpoint
 * accepts no parameters and hard-caps the signup strip at five, so a control
 * that changed something here would be a lie. The one control is Refresh: two
 * admins can be working the same queue, and a manual re-read is cheaper than
 * wondering whether the tab has been open an hour. The counts go stale because
 * OTHER screens act, and those screens own the invalidation of
 * `queryKeys.overview.all`.
 *
 * The screen renders as one unit: a single request feeds every tile, so a
 * failure is a whole-screen ErrorState rather than nine tiles of em dashes an
 * admin has to work out the meaning of. Note that the error branch is checked
 * BEFORE the data branch, so a failed *background* refetch replaces good
 * numbers with the error — an error you can act on beats stale numbers you
 * cannot date. The one local state with its own empty case is the signups list,
 * which is genuinely empty on a fresh install.
 */
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import type { AdminOverview } from "@lacasa/api-client";
import { PageHead } from "@/shell/PageHead";
import { Panel, PanelHead } from "@/ui/Panel";
import { Button } from "@/ui/Button";
import { Avatar } from "@/ui/Avatar";
import { Tag } from "@/ui/Tag";
import { CellMain, Table, TBody, TD, TH, THead, TR } from "@/ui/Table";
import { EmptyState, ErrorState, LoadingState } from "@/ui/States";
import { RefreshCw, Users } from "@/ui/icons";
import { formatCount, formatDateTime } from "@/lib/format";
import {
  LEAD_STATUS_ORDER,
  PUBLICATION_STATUS_KEYS,
  leadStatusLabel,
  publicationStatusLabel,
  userRoleLabel,
  userRoleTone,
} from "@/lib/labels";
import { useOverview } from "@/data/useOverview";
import { StatTile } from "./StatTile";
import { CountBreakdown, type BreakdownRow } from "./CountBreakdown";
import "./overview.scss";

/**
 * A denominator is only shown when every part of it arrived. Summing the parts
 * that happen to be present would quietly understate the total ("7 failed of
 * 31" when the real base is 354), and a wrong denominator on this surface is
 * worse than no denominator — it makes a failure rate look survivable.
 */
function sumCounts(values: Array<number | undefined>): number | undefined {
  let total = 0;
  for (const value of values) {
    if (typeof value !== "number" || !Number.isFinite(value)) return undefined;
    total += value;
  }
  return total;
}

/** "1,150 buyers · 96 agents · …" — the calm second line of a tile. */
function joinParts(parts: string[]): string {
  return parts.join(" · ");
}

export function OverviewScreen() {
  const { t } = useTranslation();
  const overview = useOverview();

  // Gated on isPending (first load, nothing cached), NOT on isFetching: a
  // background refresh must not blank a screen an admin is reading.
  if (overview.isPending) {
    return <LoadingState label={t("loadingOverview")} />;
  }

  // Before the data branch, on purpose — see the file header.
  if (overview.isError) {
    return <ErrorState error={overview.error} onRetry={() => void overview.refetch()} />;
  }

  const data = overview.data;

  return (
    <>
      <PageHead
        // Text, not a control. It states the scope of every number below: an
        // ADMIN is a WIDER role than agent, not an agent with more rows, so
        // nothing here is agent-scoped.
        note={t("platformWideAllAgents")}
        actions={
          <Button
            icon={RefreshCw}
            onClick={() => void overview.refetch()}
            disabled={overview.isFetching}
          >
            {overview.isFetching ? t("refreshing") : t("refresh")}
          </Button>
        }
      />

      <StatTiles data={data} />

      <div className="overview-columns">
        <RecentSignupsPanel signups={data.recentSignups} />

        <div className="overview-columns__stack">
          <Panel>
            <PanelHead title={t("leadPipelineTitle")} sub={t("leadPipelineSub")} />
            <CountBreakdown
              rows={LEAD_STATUS_ORDER.map<BreakdownRow>((status) => ({
                key: status,
                label: leadStatusLabel(t, status),
                // Indexed, not defaulted to 0: a status the payload omits is a
                // status this build cannot vouch for (lib/format.ts's rule).
                // Guarded on `leads` itself as well — the deleted build guarded
                // it in the tile and not in this panel, so a payload missing
                // the whole block threw here.
                value: data.leads?.byStatus?.[status],
              }))}
              total={data.leads?.total ?? 0}
            />
          </Panel>

          <Panel>
            {/* "Every publication attempt", not "crossposts to OLX and
                Instagram": AdPublication spans five channels (schema.prisma's
                PublishChannel), of which only two are extension-assisted. */}
            <PanelHead title={t("publicationsTitle")} sub={t("publicationsSub")} />
            <CountBreakdown
              rows={PUBLICATION_STATUS_KEYS.map<BreakdownRow>((status) => ({
                key: status,
                label: publicationStatusLabel(t, status),
                value: data.publications?.[status],
              }))}
              // `?? 0`: an unknown total makes every bar render empty rather
              // than scaling against a fabricated base.
              total={sumCounts(PUBLICATION_STATUS_KEYS.map((s) => data.publications?.[s])) ?? 0}
            />
          </Panel>
        </div>
      </div>
    </>
  );
}

function StatTiles({ data }: { data: AdminOverview }) {
  const { t } = useTranslation();
  const users = data.users;
  const applications = data.applications;
  const ads = data.ads;
  const publications = data.publications;

  const publicationTotal = sumCounts(PUBLICATION_STATUS_KEYS.map((s) => publications?.[s]));
  const pending = applications?.pending;

  return (
    // Five tiles, not the mockup's six: MRR and premium counts have no data
    // model (see the file header). The row WRAPS rather than forcing all five
    // onto one line — three readable tiles per row beats five squeezed numerals.
    <div className="overview-tiles">
      <StatTile
        label={t("statTotalUsers")}
        value={users?.total}
        sub={joinParts([
          t("countBuyers", { value: formatCount(users?.buyers) }),
          t("countAgents", { value: formatCount(users?.agents) }),
          t("countCoworkers", { value: formatCount(users?.coworkers) }),
          t("countAdmins", { value: formatCount(users?.admins) }),
        ])}
      />

      <StatTile
        label={t("statPendingApplications")}
        value={pending}
        signal
        to="/applications"
        sub={
          // Strict `=== 0`, and that strictness is the point: an UNKNOWN queue
          // is not a clear queue, so an undefined pending count falls through
          // to the approved/rejected line and shows "—" for the value.
          pending === 0
            ? t("queueClear")
            : joinParts([
                t("countApproved", { value: formatCount(applications?.approved) }),
                t("countRejected", { value: formatCount(applications?.rejected) }),
              ])
        }
      />

      <StatTile
        label={t("statListings")}
        value={ads?.total}
        sub={joinParts([
          t("countActive", { value: formatCount(ads?.active) }),
          t("countSold", { value: formatCount(ads?.sold) }),
          t("countDraft", { value: formatCount(ads?.draft) }),
        ])}
      />

      <StatTile
        label={t("statLeads")}
        value={data.leads?.total}
        sub={t("countStillNew", { value: formatCount(data.leads?.byStatus?.new) })}
      />

      {/* The audit log is the nearest thing to a screen that acts on this, and
          it is an imperfect fit worth stating: ActivityEvent records the
          extension-assisted crossposts (the olx and ig events) but not a failed
          Telegram or YouTube publication, so the log explains SOME of this
          count, not all of it. The alternatives were both worse — inventing a
          /publications route would claim a screen exists, and appending a
          `?type=` the audit screen has not agreed to read would be a contract
          it never signed. It links to the UNFILTERED log. */}
      <StatTile
        label={t("statFailedPublications")}
        value={publications?.failed}
        signal
        to="/audit"
        sub={
          publicationTotal === undefined
            ? t("ofUnknownAttempts")
            : t("ofPublicationRecords", { value: formatCount(publicationTotal) })
        }
      />
    </div>
  );
}

function RecentSignupsPanel({ signups }: { signups: AdminOverview["recentSignups"] }) {
  const { t } = useTranslation();
  // A malformed payload lands in the empty state rather than crashing the one
  // screen that would tell an admin something is wrong with the server.
  const rows = Array.isArray(signups) ? signups : [];

  return (
    <Panel>
      <PanelHead title={t("recentSignupsTitle")} sub={t("recentSignupsSub")}>
        {/* Not a filter and not a link — a plain statement of what the list is,
            because "5 rows" and "the 5 newest of 1,284" are different facts and
            the panel would otherwise read as a truncated table with a missing
            "show all". Do not turn this into a sort toggle. */}
        <span className="overview-signups__note">{t("newestFirst")}</span>
      </PanelHead>

      {rows.length === 0 ? (
        <EmptyState
          icon={Users}
          title={t("noAccountsYet")}
          sub={t("noAccountsYetOverviewSub")}
        />
      ) : (
        <Table ariaLabel={t("recentSignupsTitle")}>
          <THead>
            <TR>
              <TH>{t("columnUser")}</TH>
              <TH>{t("columnRole")}</TH>
              <TH align="right">{t("columnSignedUp")}</TH>
            </TR>
          </THead>
          <TBody>
            {rows.map((signup) => (
              // Rows are NOT clickable: the only navigation affordances on this
              // screen are the two linked tiles and the All users link below.
              <TR key={signup.id}>
                <TD>
                  <CellMain
                    thumb={<Avatar name={signup.fullName} round />}
                    title={signup.fullName}
                    sub={signup.email}
                  />
                </TD>
                <TD>
                  {/* `userRoleLabel`/`userRoleTone` widen to the raw wire value
                      and a neutral tone. The type says the role is one of four,
                      but the API can ship a fifth before this app is redeployed,
                      and a blank cell where the role should be is the worst
                      possible outcome on the list of accounts that just
                      appeared. */}
                  <Tag tone={userRoleTone(signup.role)}>{userRoleLabel(t, signup.role)}</Tag>
                </TD>
                <TD align="right" mono>
                  {formatDateTime(signup.createdAt)}
                </TD>
              </TR>
            ))}
          </TBody>
        </Table>
      )}

      {/* Rendered in BOTH the populated and the empty case: an admin who has
          just been told nobody has registered still needs the way through to
          the directory. */}
      <div className="overview-signups__foot">
        <Link to="/users" className="overview-signups__link">
          {t("allUsers")}
        </Link>{" "}
        {t("allUsersNote")}
      </div>
    </Panel>
  );
}
