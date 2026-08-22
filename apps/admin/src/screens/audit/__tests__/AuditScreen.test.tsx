/**
 * AuditScreen.test — the RENDER half of this screen's coverage (the wire half
 * is useAudit.test.ts, which drives the real api-client resource against a
 * fake Transport and asserts the outbound request).
 *
 * Only `@/data/useAudit`'s two hooks are mocked, so the query envelope can be
 * posed exactly (pending, error-with-rows, error-without-rows, last page) —
 * states that are otherwise only reachable by choreographing a server. The
 * screen, every ui/ primitive, the row/filter/drawer logic, i18next and MUI
 * all run for real. `auditRowsOf` is deliberately NOT mocked (importOriginal
 * keeps it), so the page-flattening the table depends on is the real
 * implementation.
 *
 * Nothing else needs faking: unlike the deleted build, this app has exactly
 * one React in the tree, so react-query's provider and lucide's icons mount
 * normally.
 */
import { fireEvent, screen, within } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "@lacasa/domain";
import type { AdminAuditRow } from "@lacasa/api-client";
import { formatDate, formatTimeOfDay } from "@/lib/format";
import {
  useAuditEvents,
  useRefreshAudit,
  type AuditFilters,
  type AuditPage,
  type AuditQueryResult,
} from "@/data/useAudit";
import { renderWithProviders } from "@/test/render";
import { AuditScreen } from "../AuditScreen";

vi.mock("@/data/useAudit", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/data/useAudit")>();
  return { ...actual, useAuditEvents: vi.fn(), useRefreshAudit: vi.fn() };
});

const AGENT = { id: "9c6e41af-0000-4000-8000-00000000000a", fullName: "Javlon Karimov" };

function makeRow(overrides: Partial<AdminAuditRow> = {}): AdminAuditRow {
  return {
    id: "3f0a11c2-0000-4000-8000-000000000001",
    type: "ad_created",
    createdAt: "2026-08-03T09:41:08.000Z",
    agent: AGENT,
    coworker: null,
    ad: { id: "a3f21e08-0000-4000-8000-00000000000b", title: "3-room in Chilonzor" },
    lead: null,
    meta: { channel: "olx", attempt: 2 },
    ...overrides,
  };
}

/** The InfiniteData envelope react-query would hand the screen. */
function loaded(rows: AdminAuditRow[], nextCursor: string | null = null) {
  const pages: AuditPage[] = [{ items: rows, nextCursor }];
  return { pages, pageParams: [undefined] };
}

function mockQuery(overrides: Record<string, unknown> = {}) {
  const query = {
    data: loaded([makeRow()]),
    error: null,
    isError: false,
    isPending: false,
    isFetching: false,
    hasNextPage: false,
    isFetchingNextPage: false,
    refetch: vi.fn(),
    fetchNextPage: vi.fn(),
    ...overrides,
  };
  vi.mocked(useAuditEvents).mockReturnValue(query as unknown as AuditQueryResult);
  return query;
}

/** The filters the screen last asked the data layer for. */
function lastFilters(): AuditFilters | undefined {
  return vi.mocked(useAuditEvents).mock.calls.at(-1)?.[0];
}

function render() {
  return renderWithProviders(<AuditScreen />, { withAuth: false });
}

function button(name: RegExp | string): HTMLButtonElement {
  return screen.getByRole("button", { name }) as HTMLButtonElement;
}

/** The first of several identically-named controls (one per row, typically). */
function firstButton(name: RegExp | string): HTMLButtonElement {
  const [first] = screen.getAllByRole("button", { name });
  if (!first) throw new Error(`no button named ${String(name)}`);
  return first as HTMLButtonElement;
}

/**
 * Row assertions are scoped to the table: the type filter's `<option>` list
 * carries the same eleven event labels the rows do, so an unscoped
 * `getByText("ad.created")` matches the dropdown as well as the record.
 */
function rows() {
  return within(screen.getByRole("table"));
}

function selectType(value: string) {
  fireEvent.change(screen.getByLabelText("Event type"), { target: { value } });
}

let refresh: ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.clearAllMocks();
  refresh = vi.fn();
  vi.mocked(useRefreshAudit).mockReturnValue(refresh);
  mockQuery();
});

describe("AuditScreen", () => {
  it("renders the stream newest-first, with the seconds on the prominent line", () => {
    mockQuery({
      data: loaded([
        makeRow(),
        makeRow({
          id: "3f0a11c2-0000-4000-8000-000000000002",
          type: "lead_status_changed",
          createdAt: "2026-08-03T08:12:39.000Z",
          ad: null,
          lead: { id: "7f3a0000-0000-4000-8000-00000000000c", fullName: "Dilnoza Yusupova" },
        }),
      ]),
    });

    render();

    expect(rows().getByText("3-room in Chilonzor")).toBeTruthy();
    expect(rows().getByText("Dilnoza Yusupova")).toBeTruthy();
    expect(rows().getByText("ad.created")).toBeTruthy();
    expect(rows().getByText("lead.status_changed")).toBeTruthy();
    // Formatted through the helpers the row itself uses, so the assertion
    // does not quietly depend on the machine's timezone.
    expect(rows().getByText(formatTimeOfDay("2026-08-03T09:41:08.000Z"))).toBeTruthy();
    expect(rows().getAllByText(formatDate("2026-08-03T09:41:08.000Z")).length).toBe(2);
    expect(lastFilters()).toEqual({ type: undefined, agentId: undefined });
  });

  it("states permanently that this is agent activity, not a full audit trail", () => {
    render();

    expect(screen.getByText(/not a complete audit trail/i)).toBeTruthy();
    expect(screen.getByText(/not recorded anywhere/i)).toBeTruthy();
  });

  it("keeps that caveat on screen when the log is empty, where it matters most", () => {
    mockQuery({ data: loaded([]) });

    render();

    expect(screen.getByText("No activity recorded")).toBeTruthy();
    expect(screen.getByText(/not a complete audit trail/i)).toBeTruthy();
  });

  it("ships no severity or level column", () => {
    render();

    const headers = screen
      .getAllByRole("columnheader")
      .map((header) => header.textContent?.trim());
    expect(headers).toEqual(["Time", "Event", "Acted by", "Record", ""]);
  });

  it("shows a skeleton, not an empty state, while the first page is in flight", () => {
    mockQuery({ data: undefined, isPending: true, isFetching: true });

    const { container } = render();

    expect(container.querySelectorAll("tbody tr").length).toBe(8);
    expect(screen.queryByText("No activity recorded")).toBeNull();
  });

  it("asks the data layer for the event type rather than filtering loaded rows", () => {
    render();

    selectType("olx_crosspost_aborted");

    expect(lastFilters()?.type).toBe("olx_crosspost_aborted");
    // Still every row the (stubbed) server returned — nothing was dropped on
    // the client, which on a cursor-paged stream would under-report.
    expect(screen.getByText("3-room in Chilonzor")).toBeTruthy();
  });

  it("narrows the log to a row's agent, then clears it again from the chip", () => {
    render();

    fireEvent.click(button(/Filter the log to Javlon Karimov/i));

    expect(lastFilters()?.agentId).toBe(AGENT.id);
    expect(button(/Agent: Javlon Karimov/)).toBeTruthy();
    // The row's own funnel goes inert so the same filter cannot be re-applied.
    expect(button(/Filter the log to Javlon Karimov/i).disabled).toBe(true);
    // And the panel says out loud that an agent filter also catches the
    // events their coworkers caused, since `agentId` is the owning agent.
    expect(screen.getByText(/including their coworkers/i)).toBeTruthy();

    fireEvent.click(button(/Agent: Javlon Karimov/));

    expect(lastFilters()?.agentId).toBeUndefined();
    expect(screen.queryByRole("button", { name: /Agent: Javlon Karimov/ })).toBeNull();
  });

  it("offers no agent filter on an event that records none", () => {
    mockQuery({ data: loaded([makeRow({ agent: null })]) });

    render();

    expect(button("No agent recorded on this event").disabled).toBe(true);
    expect(screen.getByText("unattributed")).toBeTruthy();
  });

  it("tells an empty filter result apart from an empty log, and can clear back", () => {
    mockQuery({ data: loaded([]) });

    render();
    selectType("ig_assist_aborted");

    expect(screen.getByText("No events match these filters")).toBeTruthy();
    expect(screen.queryByText("No activity recorded")).toBeNull();

    // Two ways out of the dead end, and both have to work: the toolbar link
    // and the button inside the empty state.
    fireEvent.click(firstButton("Clear filters"));

    expect(lastFilters()).toEqual({ type: undefined, agentId: undefined });
    expect(screen.getByText("No activity recorded")).toBeTruthy();
  });

  it("opens one row's meta drawer at a time and shows the full ids beside the JSON", () => {
    mockQuery({
      data: loaded([
        makeRow(),
        makeRow({ id: "3f0a11c2-0000-4000-8000-000000000002", meta: { channel: "instagram" } }),
      ]),
    });

    render();
    fireEvent.click(firstButton("Inspect event details"));

    expect(screen.getByText(/"channel": "olx"/)).toBeTruthy();
    // Full UUIDs, not the table's truncated prefixes — the point of the
    // drawer is to carry an id somewhere else.
    expect(screen.getByText("3f0a11c2-0000-4000-8000-000000000001")).toBeTruthy();
    expect(screen.getByText("a3f21e08-0000-4000-8000-00000000000b")).toBeTruthy();

    // The first row's eye now reads "Hide event details", so the first
    // "Inspect" control is the SECOND row's — one drawer at a time.
    fireEvent.click(firstButton("Inspect event details"));

    expect(screen.queryByText(/"channel": "olx"/)).toBeNull();
    expect(screen.getByText(/"channel": "instagram"/)).toBeTruthy();

    fireEvent.click(button("Hide event details"));

    expect(screen.queryByText(/"channel": "instagram"/)).toBeNull();
  });

  it("says so when an event carries no meta, rather than showing an empty drawer", () => {
    mockQuery({ data: loaded([makeRow({ meta: null })]) });

    render();
    fireEvent.click(button("Inspect event details"));

    expect(screen.getByText("This event recorded no meta.")).toBeTruthy();
  });

  it("attributes a coworker's event to the coworker and names the agent behind it", () => {
    mockQuery({
      data: loaded([
        makeRow({
          coworker: { id: "c0000000-0000-4000-8000-00000000000d", fullName: "Kamola Rustamova" },
        }),
      ]),
    });

    render();

    expect(screen.getByText("Kamola Rustamova")).toBeTruthy();
    expect(screen.getByText("coworker · for Javlon Karimov")).toBeTruthy();
  });

  it("marks a deleted subject as absent instead of leaving a blank cell", () => {
    mockQuery({ data: loaded([makeRow({ ad: null, lead: null })]) });

    render();

    expect(screen.getByTitle(/has been deleted/i).textContent).toBe("—");
  });

  it("pages forward only while the server says there is more", () => {
    const query = mockQuery({ data: loaded([makeRow()], "cursor-50"), hasNextPage: true });

    render();
    fireEvent.click(button("Load more"));

    expect(query.fetchNextPage).toHaveBeenCalledTimes(1);
    // "1 events loaded", not "1 of ~n": the endpoint returns no total and the
    // footer must not imply one.
    expect(screen.getByText("events loaded").textContent?.replace(/\s+/g, " ").trim()).toBe(
      "1 events loaded",
    );
  });

  it("marks the end of the list rather than leaving a dead pager", () => {
    render();

    expect(screen.queryByRole("button", { name: "Load more" })).toBeNull();
    expect(screen.getByText("End of list")).toBeTruthy();
  });

  it("surfaces the real API error instead of an empty table", () => {
    const query = mockQuery({
      data: undefined,
      isError: true,
      error: new ApiError("forbidden", "Admin role required", 403),
    });

    render();

    expect(screen.getByText("Admin role required")).toBeTruthy();
    expect(screen.queryByText("No activity recorded")).toBeNull();
    // The caveat outlives the failure too: "the log failed to load" must not
    // be read as "the log is complete and quiet".
    expect(screen.getByText(/not a complete audit trail/i)).toBeTruthy();

    fireEvent.click(button("Try again"));
    expect(query.refetch).toHaveBeenCalledTimes(1);
  });

  it("keeps the loaded rows on screen when a later page fails", () => {
    mockQuery({
      data: loaded([makeRow()], "cursor-50"),
      hasNextPage: true,
      isError: true,
      error: new ApiError("internal", "Upstream timed out", 500),
    });

    render();

    expect(screen.getByText("3-room in Chilonzor")).toBeTruthy();
    expect(within(screen.getByRole("alert")).getByText(/Upstream timed out/)).toBeTruthy();
    expect(screen.queryByText("Something went wrong")).toBeNull();
  });

  it("refreshes the stream on demand, and says so while it is refetching", () => {
    render();
    fireEvent.click(button(/^Refresh$/));
    expect(refresh).toHaveBeenCalledTimes(1);

    mockQuery({ isFetching: true });
    const { container } = render();
    expect(within(container).getByRole("button", { name: /Refreshing/ })).toBeTruthy();
  });
});
