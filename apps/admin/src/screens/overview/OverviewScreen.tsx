/**
 * src/screens/overview — the control room's landing screen: everything
 * `GET /api/admin/overview` knows about the platform, and nothing else.
 *
 * WHAT IS NOT HERE, AND WHY THAT IS THE POINT.
 * The mockup's overview opens with six KPI tiles (two of them "Premium agents"
 * and "MRR"), a twelve-day listings trend chart, and a Queues panel with rows
 * for 3D tour review, reported listings and expired Instagram tokens. There is
 * no billing model, no plan model, no tour model, no report model and no
 * time-series endpoint behind any of that. Every one of them is omitted
 * outright rather than rendered as a zero, a dash or a placeholder: on the
 * screen an operator uses to judge the health of the business, an invented
 * "$740" is not a design detail, it is a false statement — and a tile that
 * renders "—" forever is a promise that the number is coming. What survives is
 * the five aggregates the schema actually backs (users, applications, ads,
 * leads, publications) plus the recent-signups strip.
 *
 * WHERE THE AMBER GOES. Exactly two numbers on this screen are things an admin
 * can *do* something about: applications waiting for a decision, and
 * publications that failed. Those two tiles carry the surface's one signal
 * colour and link to the screen that acts on them; everything else — including
 * the two distribution panels, whose buckets do have tones in @/lib/labels —
 * is calm neutral ink. That is the whole reason a pending count is scannable
 * from across a desk (tailwind.config.js rule 2, StatTile's header).
 *
 * The screen renders as one unit: a single request feeds every tile, so a
 * failure is a whole-screen ErrorState rather than nine tiles of em dashes
 * that an admin has to work out the meaning of. The one local state that has
 * its own empty case is the signups list, which is genuinely empty on a fresh
 * install.
 */
import { Link } from "react-router-dom";
import type { AdminOverview } from "@lacasa/api-client";
import { PageHead } from "@/shell/PageHead";
import { Panel, PanelHead } from "@/ui/Panel";
import { Button } from "@/ui/Button";
import { Avatar } from "@/ui/Avatar";
import { Tag, type Tone } from "@/ui/Tag";
import { CellMain, Table, TBody, TD, TH, THead, TR } from "@/ui/Table";
import { EmptyState, ErrorState, LoadingState } from "@/ui/States";
import { ArrowsClockwiseIcon, UsersThreeIcon } from "@/ui/icons";
import { formatCount, formatDateTime } from "@/lib/format";
import {
  LEAD_STATUS_LABEL,
  LEAD_STATUS_ORDER,
  PUBLICATION_STATUS_KEYS,
  PUBLICATION_STATUS_LABEL,
  USER_ROLE_LABEL,
  USER_ROLE_TONE,
} from "@/lib/labels";
import { useOverview } from "@/data/useOverview";
import { StatTile } from "./StatTile";
import { CountBreakdown, type BreakdownRow } from "./CountBreakdown";

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

function roleLabel(role: string): string {
  return (USER_ROLE_LABEL as Record<string, string | undefined>)[role] ?? role;
}

function roleTone(role: string): Tone {
  return (USER_ROLE_TONE as Record<string, Tone | undefined>)[role] ?? "mute";
}

export function OverviewScreen() {
  const overview = useOverview();

  if (overview.isPending) {
    return <LoadingState label="Loading platform overview…" />;
  }

  if (overview.isError) {
    return <ErrorState error={overview.error} onRetry={() => void overview.refetch()} />;
  }

  const data = overview.data;

  return (
    <>
      <PageHead
        note="Platform-wide, all agents"
        actions={
          <Button
            icon={ArrowsClockwiseIcon}
            onClick={() => void overview.refetch()}
            disabled={overview.isFetching}
          >
            {/* Two admins can be working the same queue; a manual re-read is
                cheaper than wondering whether the tab has been open an hour. */}
            {overview.isFetching ? "Refreshing…" : "Refresh"}
          </Button>
        }
      />

      <StatTiles data={data} />

      <div className="grid items-start gap-3 lg:grid-cols-[1fr_340px]">
        <RecentSignupsPanel signups={data.recentSignups} />

        <div className="grid gap-3">
          <Panel>
            <PanelHead title="Lead pipeline" sub="Every lead on the platform, by status" />
            <CountBreakdown
              rows={LEAD_STATUS_ORDER.map<BreakdownRow>((status) => ({
                key: status,
                label: LEAD_STATUS_LABEL[status],
                // Indexed, not defaulted to 0: a status the payload omits is a
                // status this build cannot vouch for (lib/format.ts's rule).
                value: data.leads.byStatus?.[status],
              }))}
              total={data.leads.total}
            />
          </Panel>

          <Panel>
            {/* "Every publication attempt", not "crossposts to OLX and
                Instagram": AdPublication spans five channels (schema.prisma's
                PublishChannel), of which only two are extension-assisted. */}
            <PanelHead title="Publications" sub="Every publication attempt, by outcome" />
            <CountBreakdown
              rows={PUBLICATION_STATUS_KEYS.map<BreakdownRow>((status) => ({
                key: status,
                label: PUBLICATION_STATUS_LABEL[status],
                value: data.publications?.[status],
              }))}
              total={sumCounts(PUBLICATION_STATUS_KEYS.map((s) => data.publications?.[s])) ?? 0}
            />
          </Panel>
        </div>
      </div>
    </>
  );
}

function StatTiles({ data }: { data: AdminOverview }) {
  const users = data.users;
  const applications = data.applications;
  const ads = data.ads;
  const publications = data.publications;

  const publicationTotal = sumCounts(PUBLICATION_STATUS_KEYS.map((s) => publications?.[s]));
  const pending = applications?.pending;

  return (
    // Five tiles, not the mockup's six: MRR and premium counts have no data
    // model (see the file header). The grid wraps rather than forcing six
    // columns, so a 1280px laptop gets three readable tiles per row instead of
    // six 24px numerals squeezed to four characters wide.
    <div className="mb-3.5 grid gap-2.5 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-5">
      <StatTile
        label="Total users"
        value={users?.total}
        sub={joinParts([
          `${formatCount(users?.buyers)} buyers`,
          `${formatCount(users?.agents)} agents`,
          `${formatCount(users?.coworkers)} coworkers`,
          `${formatCount(users?.admins)} admins`,
        ])}
      />

      <StatTile
        label="Pending applications"
        value={pending}
        signal
        to="/applications"
        sub={
          pending === 0
            ? "Queue clear"
            : joinParts([
                `${formatCount(applications?.approved)} approved`,
                `${formatCount(applications?.rejected)} rejected`,
              ])
        }
      />

      <StatTile
        label="Listings"
        value={ads?.total}
        sub={joinParts([
          `${formatCount(ads?.active)} active`,
          `${formatCount(ads?.sold)} sold`,
          `${formatCount(ads?.draft)} draft`,
        ])}
      />

      <StatTile
        label="Leads"
        value={data.leads?.total}
        sub={`${formatCount(data.leads?.byStatus?.new)} still new`}
      />

      {/* The audit log is the nearest thing to a screen that acts on this, and
          it is an imperfect fit worth stating: ActivityEvent records the
          extension-assisted crossposts (the olx and ig events) but not a
          failed Telegram or YouTube publication, so the log explains SOME of
          this count, not all of it. The alternative — inventing a
          /publications route — would be a claim that a screen exists. Linking
          to the unfiltered log rather than a `?type=` the audit screen has not
          agreed to read, for the same reason. */}
      <StatTile
        label="Failed publications"
        value={publications?.failed}
        signal
        to="/audit"
        sub={
          publicationTotal === undefined
            ? "of an unknown number of attempts"
            : `of ${formatCount(publicationTotal)} publication records`
        }
      />
    </div>
  );
}

function RecentSignupsPanel({ signups }: { signups: AdminOverview["recentSignups"] }) {
  const rows = Array.isArray(signups) ? signups : [];

  return (
    <Panel>
      <PanelHead title="Recent signups" sub="The newest accounts on the platform">
        {/* Not a filter and not a link — a plain statement of what the list is,
            because "5 rows" and "the 5 newest of 1,284" are different facts and
            the panel would otherwise look like a truncated table. */}
        <span className="text-tiny text-muted">Newest first</span>
      </PanelHead>

      {rows.length === 0 ? (
        <EmptyState
          icon={UsersThreeIcon}
          title="No accounts yet"
          sub="Nobody has registered on this platform. The five newest accounts will appear here as soon as somebody does."
        />
      ) : (
        <Table>
          <THead>
            <TR>
              <TH>User</TH>
              <TH>Role</TH>
              <TH align="right">Signed up</TH>
            </TR>
          </THead>
          <TBody>
            {rows.map((signup) => (
              <TR key={signup.id}>
                <TD>
                  <CellMain
                    thumb={<Avatar name={signup.fullName} round />}
                    title={signup.fullName}
                    sub={signup.email}
                  />
                </TD>
                <TD>
                  {/* Typed as UserRoleKey, so a role this build does not know
                      about is a compile error — but the API can still ship one
                      before this app is redeployed, and a blank cell where the
                      role should be is the worst possible outcome on the list
                      of accounts that just appeared. Same widening @/lib/labels
                      uses for audit types. */}
                  <Tag tone={roleTone(signup.role)}>{roleLabel(signup.role)}</Tag>
                </TD>
                <TD align="right" mono>
                  {formatDateTime(signup.createdAt)}
                </TD>
              </TR>
            ))}
          </TBody>
        </Table>
      )}

      <div className="border-t border-line px-[15px] py-2.5 text-tiny text-muted">
        <Link
          to="/users"
          className="font-semibold text-ink-2 underline-offset-2 hover:text-ink hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc"
        >
          All users
        </Link>{" "}
        — search, filter and change roles.
      </div>
    </Panel>
  );
}
