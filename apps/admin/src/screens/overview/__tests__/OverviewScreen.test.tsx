/**
 * OverviewScreen.test — mounts the real screen against a mocked data layer
 * (`@/data/useOverview`), the same way apps/console tests its screens: the
 * hook is the seam, so no fetch, no QueryClient and no token storage need to
 * exist for a render.
 *
 * Two dependencies are replaced with stand-ins for a reason that has nothing
 * to do with this screen — react-router-dom and @phosphor-icons/react are
 * both hoisted to the workspace root and load the root's React 18 while every
 * file under src/ loads this app's nested React 19. See each `vi.mock` below;
 * apps/console's leads test hit the identical wall and documents the same
 * root cause.
 *
 * Beyond the happy path, three of these tests exist to pin down rules that are
 * easy to "tidy" away later:
 *   · amber appears on exactly the two actionable tiles, and NOT on a queue of
 *     zero (StatTile's header);
 *   · a bucket the payload omits renders as an em dash, never as 0
 *     (lib/format.ts's header);
 *   · nothing on this screen mentions MRR, premium or plans — the mockup has
 *     tiles for all three and no model backs any of them.
 */
import type { ReactNode } from "react";
import { act } from "react";
import { screen, within } from "@testing-library/dom";
import type { UseQueryResult } from "@tanstack/react-query";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AdminOverview } from "@lacasa/api-client";
import { ApiError } from "@lacasa/domain";
import { EM_DASH, formatDateTime } from "@/lib/format";
import { useOverview } from "@/data/useOverview";
import { render } from "@/test/render";
import { OverviewScreen } from "../OverviewScreen";

vi.mock("@/data/useOverview", () => ({ useOverview: vi.fn() }));

/**
 * react-router-dom is mocked down to the one export this screen uses. It is
 * hoisted to the WORKSPACE ROOT (there is no copy under
 * apps/admin/node_modules, unlike react/react-dom), so its own
 * `require("react")` resolves the root's React 18 while every file under
 * src/ resolves this app's nested React 19 — and a real `<MemoryRouter>`
 * mounted through this file's (correctly nested) react-dom root dies on
 * `Cannot read properties of null (reading 'useRef')`, verified.
 * `resolve.dedupe` in vitest.config.ts does not reach it: vitest externalises
 * node_modules dependencies and hands them to Node's own resolution, which
 * dedupe never sees. Same class of failure apps/console documents for
 * @testing-library/react and @phosphor-icons/react.
 *
 * The stand-in still renders a real `<a href>`, so "which screen does this
 * tile send an admin to" is asserted against the DOM rather than against a
 * spy on a router call.
 */
vi.mock("react-router-dom", () => ({
  Link: ({ to, children, ...rest }: { to: string; children: ReactNode }) => (
    <a href={to} {...rest}>
      {children}
    </a>
  ),
}));

/**
 * Every Phosphor glyph, swapped for a bare `<svg>`. Same hoisting split as
 * above, one layer deeper: @phosphor-icons/react builds its elements with the
 * root's React 18 JSX runtime, and React 19's reconciler refuses them with "A
 * React Element from an older version of React was rendered" — also verified,
 * not assumed. Only the icon components are replaced; @/ui/icons' own
 * `IconComponent` type and any non-component export stay real.
 */
vi.mock("@/ui/icons", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/ui/icons")>();
  const FakeIcon = (props: Record<string, unknown>) => <svg data-testid="fake-icon" {...props} />;
  const faked = Object.fromEntries(Object.keys(actual).map((key) => [key, FakeIcon]));
  return { ...actual, ...faked };
});

type OverviewQuery = UseQueryResult<AdminOverview, ApiError>;

function makeOverview(overrides: Partial<AdminOverview> = {}): AdminOverview {
  return {
    users: { total: 1284, buyers: 1150, agents: 96, coworkers: 34, admins: 4 },
    applications: { pending: 3, approved: 96, rejected: 12 },
    ads: { total: 466, active: 412, sold: 41, draft: 13 },
    leads: {
      total: 124,
      byStatus: {
        new: 41,
        could_not_connect: 12,
        need_to_call_back: 18,
        rejected: 22,
        accepted: 31,
      },
    },
    publications: { published: 318, failed: 7, pending: 24, drafted_awaiting_review: 5 },
    recentSignups: [
      {
        id: "u-1",
        fullName: "Dilnoza Yusupova",
        email: "dilnoza@lacasa.uz",
        role: "user",
        createdAt: "2026-08-12T09:05:00.000Z",
      },
      {
        id: "u-2",
        fullName: "Otabek Yusupov",
        email: "otabek@lacasa.uz",
        role: "agent",
        createdAt: "2026-08-11T17:48:00.000Z",
      },
    ],
    ...overrides,
  };
}

function mockOverviewQuery(overrides: Partial<OverviewQuery>) {
  const refetch = vi.fn();
  vi.mocked(useOverview).mockReturnValue({
    data: undefined,
    error: null,
    isPending: false,
    isError: false,
    isFetching: false,
    refetch,
    ...overrides,
  } as unknown as OverviewQuery);
  return { refetch };
}

function mockLoaded(data: AdminOverview = makeOverview()) {
  return mockOverviewQuery({ data, isPending: false, isError: false });
}

function renderScreen() {
  return render(<OverviewScreen />);
}

/** The tile that carries `label`, as the element that owns its border/wash. */
function tile(label: string): HTMLElement {
  const heading = screen.getByText(label);
  const element = heading.closest("a") ?? heading.parentElement?.parentElement;
  if (!element) throw new Error(`No tile found for "${label}"`);
  return element as HTMLElement;
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe("OverviewScreen", () => {
  it("renders every aggregate the payload carries", () => {
    mockLoaded();
    renderScreen();

    expect(within(tile("Total users")).getByText("1,284")).toBeTruthy();
    expect(
      within(tile("Total users")).getByText("1,150 buyers · 96 agents · 34 coworkers · 4 admins"),
    ).toBeTruthy();

    expect(within(tile("Pending applications")).getByText("3")).toBeTruthy();
    expect(within(tile("Pending applications")).getByText("96 approved · 12 rejected")).toBeTruthy();

    expect(within(tile("Listings")).getByText("466")).toBeTruthy();
    expect(within(tile("Listings")).getByText("412 active · 41 sold · 13 draft")).toBeTruthy();

    expect(within(tile("Leads")).getByText("124")).toBeTruthy();
    expect(within(tile("Leads")).getByText("41 still new")).toBeTruthy();

    expect(within(tile("Failed publications")).getByText("7")).toBeTruthy();
    expect(within(tile("Failed publications")).getByText("of 354 publication records")).toBeTruthy();
  });

  it("breaks the lead pipeline and the publication outcomes down by bucket", () => {
    mockLoaded();
    const { container } = renderScreen();

    const pipeline = container.querySelector("dl");
    if (!pipeline) throw new Error("no breakdown list rendered");
    expect(within(pipeline as HTMLElement).getByText("Could not connect")).toBeTruthy();
    expect(within(pipeline as HTMLElement).getByText("41")).toBeTruthy();

    // Publication buckets use @/lib/labels' wording, not the raw wire keys.
    expect(screen.getByText("Awaiting review")).toBeTruthy();
    expect(screen.getByText("Not published")).toBeTruthy();
    expect(screen.getByText("318")).toBeTruthy();
  });

  it("points the two actionable numbers at the screens that act on them", () => {
    mockLoaded();
    renderScreen();

    expect(tile("Pending applications").getAttribute("href")).toBe("/applications");
    expect(tile("Failed publications").getAttribute("href")).toBe("/audit");
    expect(screen.getByRole("link", { name: "All users" }).getAttribute("href")).toBe("/users");
  });

  it("spends the amber signal on those two tiles and on nothing else", () => {
    mockLoaded();
    const { container } = renderScreen();

    const alerted = Array.from(container.querySelectorAll(".border-acc-line"));
    expect(alerted).toHaveLength(2);
    expect(alerted.map((element) => element.textContent?.slice(0, 20))).toEqual([
      expect.stringContaining("Pending applications"),
      expect.stringContaining("Failed publications"),
    ]);
  });

  it("does not raise the alert for a queue of zero", () => {
    mockLoaded(
      makeOverview({
        applications: { pending: 0, approved: 96, rejected: 12 },
        publications: { published: 318, failed: 0, pending: 24, drafted_awaiting_review: 5 },
      }),
    );
    const { container } = renderScreen();

    expect(container.querySelectorAll(".border-acc-line")).toHaveLength(0);
    // Still a link, and still says which state it is in — an unlit tile has to
    // read as "nothing is waiting", not as a tile that failed to render.
    expect(tile("Pending applications").getAttribute("href")).toBe("/applications");
    expect(screen.getByText("Queue clear")).toBeTruthy();
  });

  it("renders a bucket the payload omitted as an em dash, never as zero", () => {
    const data = makeOverview();
    // A server that stopped reporting one lead status: the row must not claim
    // there are zero rejected leads.
    delete (data.leads.byStatus as Partial<AdminOverview["leads"]["byStatus"]>).rejected;
    mockLoaded(data);
    const { container } = renderScreen();

    const rows = Array.from(container.querySelectorAll("dl > div"));
    const rejectedRow = rows.find((row) => row.textContent?.startsWith("Rejected"));
    expect(rejectedRow?.textContent).toContain(EM_DASH);
    expect(rejectedRow?.textContent).not.toContain("0");
  });

  it("keeps the failure denominator honest when a publication bucket is missing", () => {
    const data = makeOverview();
    delete (data.publications as Partial<AdminOverview["publications"]>).pending;
    mockLoaded(data);
    renderScreen();

    expect(
      within(tile("Failed publications")).getByText("of an unknown number of attempts"),
    ).toBeTruthy();
  });

  it("lists the newest accounts with their role and signup time", () => {
    const data = makeOverview();
    mockLoaded(data);
    renderScreen();

    const first = data.recentSignups[0];
    if (!first) throw new Error("fixture has no signups");
    const row = screen.getByText(first.fullName).closest("tr");
    if (!row) throw new Error("signup row not rendered");
    expect(within(row).getByText(first.email)).toBeTruthy();
    expect(within(row).getByText("Buyer")).toBeTruthy();
    // Asserted against raw textContent rather than getByText: the formatter's
    // "dd.mm.yyyy | hh:mm" carries the locale's own spacing, which
    // testing-library's default normalizer collapses on the DOM side but not
    // on the expected side, so the two would never compare equal.
    expect(row.textContent).toContain(formatDateTime(first.createdAt));

    expect(screen.getByText("Otabek Yusupov")).toBeTruthy();
    expect(screen.getByText("Agent")).toBeTruthy();
  });

  it("explains an empty signup list rather than showing an empty table", () => {
    mockLoaded(makeOverview({ recentSignups: [] }));
    renderScreen();

    expect(screen.getByText("No accounts yet")).toBeTruthy();
    expect(screen.queryByRole("table")).toBeNull();
    // The aggregates are a separate fact and still render.
    expect(within(tile("Total users")).getByText("1,284")).toBeTruthy();
  });

  it("shows the real error and retries the one request the screen makes", () => {
    const { refetch } = mockOverviewQuery({
      isError: true,
      error: new ApiError("forbidden", "Admin role required.", 403),
    });
    renderScreen();

    expect(screen.getByRole("alert")).toBeTruthy();
    expect(screen.getByText("Admin role required.")).toBeTruthy();
    // ErrorState prints the API's error code next to the prose: an admin who
    // sees "forbidden" knows their session, not the server, is the problem.
    expect(screen.getByText("forbidden")).toBeTruthy();

    act(() => {
      screen.getByRole("button", { name: "Try again" }).click();
    });
    expect(refetch).toHaveBeenCalledTimes(1);
  });

  it("shows a loading state instead of a screen full of zeroes", () => {
    mockOverviewQuery({ isPending: true, isFetching: true });
    renderScreen();

    expect(screen.getByRole("status")).toBeTruthy();
    expect(screen.queryByText("Total users")).toBeNull();
  });

  it("refreshes on demand and says so while the request is in flight", () => {
    const { refetch } = mockLoaded();
    const { rerender } = renderScreen();

    act(() => {
      screen.getByRole("button", { name: "Refresh" }).click();
    });
    expect(refetch).toHaveBeenCalledTimes(1);

    mockOverviewQuery({ data: makeOverview(), isFetching: true });
    rerender(<OverviewScreen />);
    const refreshing = screen.getByRole("button", { name: "Refreshing…" });
    expect((refreshing as HTMLButtonElement).disabled).toBe(true);
  });

  it("claims nothing the schema cannot back", () => {
    mockLoaded();
    const { container } = renderScreen();

    // MRR, premium plans, 3D tours and reported listings are all in the
    // mockup's overview and none of them has a model. A tile for any of them
    // would be a fabricated figure on the screen an operator trusts most.
    expect(container.textContent).not.toMatch(/mrr|premium|plan|tour|report/i);
  });
});
