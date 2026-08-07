/**
 * StatisticsScreen.test.tsx — every hook the screen reads from `@/data/*` is
 * mocked (react-query itself is hoisted to the workspace root and pinned to
 * a different React major there — see @/test/render's file header for the
 * full root-cause writeup); `@/ui/icons` is mocked too so `Flag`'s real
 * `EyeIcon` import doesn't hit the same conflict on mount.
 */
import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { CoworkerStatisticEvent, Coworker, Lead } from "@lacasa/api-client";
import type { AdsStatistics } from "@lacasa/api-client";
import { render } from "@/test/render";
import { StatisticsScreen } from "../StatisticsScreen";
import { useAdsStatistics, useCoworkerStatistics } from "@/data/useStatistics";
import { useLeads } from "@/data/useLeads";
import { useCoworkers } from "@/data/useCoworkers";

vi.mock("@/data/useStatistics", () => ({ useAdsStatistics: vi.fn(), useCoworkerStatistics: vi.fn() }));
vi.mock("@/data/useLeads", () => ({ useLeads: vi.fn() }));
vi.mock("@/data/useCoworkers", () => ({ useCoworkers: vi.fn() }));

// A plain object built from the real export names — NOT a catch-all Proxy.
// vitest `await`s this factory's return value, and `await` probes `.then`;
// a Proxy that answers every key with a function is a thenable whose `then`
// never calls resolve, so the worker deadlocks silently while collecting
// this file (that was the workspace's "vitest run never terminates" hang).
vi.mock("@/ui/icons", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/ui/icons")>();
  function icon(name: string) {
    return function MockIcon(props: Record<string, unknown>) {
      return <svg data-testid={`icon-${name}`} {...props} />;
    };
  }
  return Object.fromEntries(Object.keys(actual).map((key) => [key, icon(key)]));
});

function adsStatsResult(
  overrides: Partial<ReturnType<typeof useAdsStatistics>> = {},
): ReturnType<typeof useAdsStatistics> {
  return {
    data: { adsNewCount: 42, adsSoldCount: 11 } satisfies AdsStatistics,
    isLoading: false,
    isError: false,
    error: null,
    ...overrides,
  } as unknown as ReturnType<typeof useAdsStatistics>;
}

function coworkerEventsResult(
  overrides: Partial<ReturnType<typeof useCoworkerStatistics>> = {},
): ReturnType<typeof useCoworkerStatistics> {
  return {
    data: [] as CoworkerStatisticEvent[],
    isLoading: false,
    isError: false,
    ...overrides,
  } as unknown as ReturnType<typeof useCoworkerStatistics>;
}

function leadsResult(overrides: Partial<ReturnType<typeof useLeads>> = {}): ReturnType<typeof useLeads> {
  return {
    data: [] as Lead[],
    isLoading: false,
    isError: false,
    ...overrides,
  } as unknown as ReturnType<typeof useLeads>;
}

function coworkersResult(overrides: Partial<ReturnType<typeof useCoworkers>> = {}): ReturnType<typeof useCoworkers> {
  return {
    data: [] as Coworker[],
    isLoading: false,
    isError: false,
    ...overrides,
  } as unknown as ReturnType<typeof useCoworkers>;
}

function makeLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: "l1",
    fullName: "Dilnoza Yusupova",
    phone: "+998901234501",
    email: null,
    budget: null,
    comment: null,
    conversationComment: null,
    status: "new",
    source: null,
    callbackDate: null,
    active: true,
    agentId: "agent1",
    coworkerId: "",
    createdAt: { seconds: 0 },
    updatedAt: { seconds: 0 },
    ...overrides,
  };
}

function makeCoworker(overrides: Partial<Coworker> = {}): Coworker {
  return {
    id: "cw1",
    fullName: "Sardor Abdullayev",
    email: "sardor@lacasa.uz",
    phoneNumber: null,
    avatar: null,
    agentId: "agent1",
    ...overrides,
  };
}

beforeEach(() => {
  vi.mocked(useAdsStatistics).mockReturnValue(adsStatsResult());
  vi.mocked(useCoworkerStatistics).mockReturnValue(coworkerEventsResult());
  vi.mocked(useLeads).mockReturnValue(leadsResult());
  vi.mocked(useCoworkers).mockReturnValue(coworkersResult());
});

describe("StatisticsScreen — populated", () => {
  it("renders the four real stat totals with no fabricated delta text anywhere", () => {
    vi.mocked(useLeads).mockReturnValue(leadsResult({ data: [makeLead()] }));
    // Two coworkers, one lead — every tile total stays distinct.
    vi.mocked(useCoworkers).mockReturnValue(
      coworkersResult({ data: [makeCoworker(), makeCoworker({ id: "cw2", fullName: "Aziz Karimov" })] }),
    );
    const { container } = render(<StatisticsScreen />);

    // Scoped to .text-stat: the chart's real-totals bars repeat 42 and 11 in
    // caption spans, so an unscoped getByText finds two of each.
    expect(screen.getByText("42", { selector: ".text-stat" })).toBeInTheDocument();
    expect(screen.getByText("11", { selector: ".text-stat" })).toBeInTheDocument();
    expect(screen.getByText("1", { selector: ".text-stat" })).toBeInTheDocument(); // Active leads count
    expect(screen.getByText("2", { selector: ".text-stat" })).toBeInTheDocument(); // Coworkers count
    // Never a fabricated trend — PLAN.md's "+12 vs last month" has no real backing.
    expect(container.textContent).not.toMatch(/vs last month/i);
    expect(container.textContent).not.toMatch(/\+\d+/);
  });

  it("flags the missing activity-feed endpoint instead of rendering a fabricated list", () => {
    render(<StatisticsScreen />);
    expect(screen.getByText(/no activity-feed endpoint/i)).toBeInTheDocument();
  });

  it("flags that the chart has no real day-by-day series and renders the two real totals instead", () => {
    render(<StatisticsScreen />);
    expect(screen.getByText(/no day-by-day breakdown/i)).toBeInTheDocument();
  });

  it("re-queries ad statistics with the newly picked period", async () => {
    render(<StatisticsScreen />);
    await userEvent.click(screen.getByRole("button", { name: "Today" }));
    expect(useAdsStatistics).toHaveBeenLastCalledWith("today");
  });

  it("marks exactly the Active leads tile as the one full-lime stat tile", () => {
    const { container } = render(<StatisticsScreen />);
    // Scoped to tiles (.rounded-card): the chart's "Created" bar is also
    // bg-accent by design, so a bare .bg-accent query finds two elements.
    const loudTiles = [...container.querySelectorAll(".rounded-card.bg-accent")];
    expect(loudTiles).toHaveLength(1);
    expect(loudTiles[0]?.textContent).toContain("Active leads");
  });
});

describe("StatisticsScreen — loading/error", () => {
  it("shows '…' while ad statistics are loading, not a fabricated 0", () => {
    vi.mocked(useAdsStatistics).mockReturnValue(adsStatsResult({ data: undefined, isLoading: true }));
    render(<StatisticsScreen />);
    expect(screen.getAllByText("…").length).toBeGreaterThanOrEqual(2);
  });

  it("shows '—' when ad statistics fail to load, not a fabricated 0", () => {
    vi.mocked(useAdsStatistics).mockReturnValue(adsStatsResult({ data: undefined, isError: true }));
    render(<StatisticsScreen />);
    expect(screen.getAllByText("—").length).toBeGreaterThanOrEqual(2);
  });
});
