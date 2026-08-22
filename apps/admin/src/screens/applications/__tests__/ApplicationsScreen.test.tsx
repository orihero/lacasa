/**
 * ApplicationsScreen.test — the review queue's UI.
 *
 * The DATA HOOKS are mocked; the 409 GUARD IS NOT. `isApplicationAlreadyDecided`
 * is kept real (via importOriginal) because it is the behaviour under test in the
 * last describe block — a mocked guard would assert only that this file calls
 * itself. The request side of the contract is covered by useApplications.test.ts,
 * which drives the real @lacasa/api-client over a faked Transport.
 *
 * Mocking the hooks rather than seeding a real QueryClient is a choice about what
 * these assertions are for: several of them are statements about the arguments
 * the screen passes DOWN ("the hook is called with 'rejected' after the tab
 * changes", "mutate is called with exactly { userId, decision }", "only the row
 * whose id matches the in-flight variables is disabled"), and those are cheapest
 * and most legible when the seam is the hook itself. The old app's OTHER mocking
 * gymnastics — a hand-rolled render(), a faked icon module — were React 18/19
 * hoisting workarounds and are gone: this suite mounts through the app's real
 * providers and renders real lucide glyphs.
 */
import { screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "@lacasa/domain";
import { formatDateTime } from "@/lib/format";
import { useApplications, useDecideApplication } from "@/data/useApplications";
import { renderWithProviders } from "@/test/render";
import { ApplicationsScreen } from "../ApplicationsScreen";
import { makeApplication, makeApplicationWithoutProfile, makePage, makeSoloApplication } from "./fixtures";

vi.mock("@/data/useApplications", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/data/useApplications")>();
  return { ...actual, useApplications: vi.fn(), useDecideApplication: vi.fn() };
});

type ApplicationsQuery = ReturnType<typeof useApplications>;
type DecideMutation = ReturnType<typeof useDecideApplication>;

function render() {
  // withAuth: false — this screen never reads the session, and the real
  // AuthProvider would fire a mount-time GET /auth/me that has nothing to do
  // with anything asserted here.
  return renderWithProviders(<ApplicationsScreen />, { withAuth: false });
}

function mockQuery(overrides: Record<string, unknown> = {}) {
  const query = {
    data: undefined,
    isPending: false,
    isError: false,
    error: null,
    hasNextPage: false,
    isFetchingNextPage: false,
    fetchNextPage: vi.fn(),
    refetch: vi.fn(),
    ...overrides,
  } as unknown as ApplicationsQuery;
  vi.mocked(useApplications).mockReturnValue(query);
  return query;
}

/** One loaded page of rows — the shape useInfiniteQuery hands back. */
function mockRows(rows: Parameters<typeof makePage>[0], nextCursor: string | null = null) {
  return mockQuery({
    data: { pages: [makePage(rows, nextCursor)], pageParams: [null] },
    hasNextPage: nextCursor !== null,
  });
}

function mockDecide(overrides: Record<string, unknown> = {}) {
  const mutation = {
    mutate: vi.fn(),
    reset: vi.fn(),
    isPending: false,
    isError: false,
    error: null,
    variables: undefined,
    ...overrides,
  } as unknown as DecideMutation;
  vi.mocked(useDecideApplication).mockReturnValue(mutation);
  return mutation;
}

/** The already-decided 409, built the way lib/apiClient.ts reconstructs it. */
function alreadyDecidedError(): ApiError {
  const error = new ApiError("internal" as never, "This application has already been decided", 409);
  Object.defineProperty(error, "code", { value: "not_pending" });
  return error;
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe("ApplicationsScreen — loading, empty and error states", () => {
  it("shows a six-row skeleton while the first page is in flight, and no applicant", () => {
    mockQuery({ isPending: true });
    mockDecide();

    const { container } = render();

    expect(container.querySelectorAll("tbody tr")).toHaveLength(6);
    expect(container.querySelector(".MuiSkeleton-pulse")).not.toBeNull();
    expect(screen.queryByText("Otabek Yusupov")).not.toBeInTheDocument();
  });

  it("says the queue is clear — not just 'no rows' — when nothing is pending", () => {
    mockRows([]);
    mockDecide();

    const { container } = render();

    expect(screen.getByText("The queue is clear")).toBeInTheDocument();
    expect(
      screen.getByText("No realtor application is waiting on a decision."),
    ).toBeInTheDocument();
    expect(container.querySelectorAll("tbody tr")).toHaveLength(0);
  });

  it("surfaces the real error message and wires Try again to refetch()", async () => {
    const query = mockQuery({ isError: true, error: new Error("Network down") });
    mockDecide();

    render();

    expect(screen.getByText("Network down")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(query.refetch).toHaveBeenCalledOnce();
  });

  it("keeps already-loaded rows on screen when a refresh fails, rather than blanking the queue", () => {
    mockQuery({
      data: { pages: [makePage([makeApplication()])], pageParams: [null] },
      isError: true,
      error: new Error("Network down"),
    });
    mockDecide();

    render();

    expect(screen.getByText("Otabek Yusupov")).toBeInTheDocument();
    expect(screen.getByText(/rows below are from the last successful load/)).toBeInTheDocument();
  });
});

describe("ApplicationsScreen — the queue", () => {
  it("renders the applicant, kind, agency, team size and applied-at from the row", () => {
    mockRows([makeApplication()]);
    mockDecide();

    render();

    expect(screen.getByText("Otabek Yusupov")).toBeInTheDocument();
    expect(screen.getByText("otabek@lacasa.uz")).toBeInTheDocument();
    expect(screen.getByText("Agency")).toBeInTheDocument();
    expect(screen.getByText("Yusupov Realty")).toBeInTheDocument();
    expect(screen.getByText("6–15")).toBeInTheDocument();
    // The applied-at column reads realtor.appliedAt, NOT the account's
    // createdAt — the two are months apart on this fixture.
    const applied = formatDateTime("2026-08-01T14:22:00.000Z").replace(/\s+/g, " ");
    expect(screen.getByText(applied)).toBeInTheDocument();
  });

  it("renders a solo applicant's blank fields as em dashes, never as empty cells", () => {
    mockRows([makeSoloApplication()]);
    mockDecide();

    render();

    expect(screen.getByText("Solo")).toBeInTheDocument();
    // Agency name and team size — two genuinely absent values on a solo row.
    expect(screen.getAllByText("—")).toHaveLength(2);
    // No hover text on those two: "the applicant left this blank" needs no
    // explaining, unlike a payload that carried no application at all.
    for (const dash of screen.getAllByText("—")) {
      expect(dash).not.toHaveAttribute("title");
    }
  });

  it("renders a row whose application block never arrived, instead of taking the whole app down with it", () => {
    mockRows([makeApplicationWithoutProfile()]);
    mockDecide();

    render();

    expect(screen.getByText("Otabek Yusupov")).toBeInTheDocument();
    // Kind, agency name, team size and applied-at: four facts the payload
    // carries nothing for, every one reported absent, none invented.
    const dashes = screen.getAllByText("—");
    expect(dashes).toHaveLength(4);
    for (const dash of dashes) {
      expect(dash).toHaveAttribute(
        "title",
        "This account carries a realtor status but no application details — nothing was recorded when the status was set.",
      );
    }
    // The decision endpoints key on realtorStatus, which is what put this row in
    // the list — so it is still decidable.
    expect(screen.getByRole("button", { name: "Approve Otabek Yusupov" })).toBeEnabled();
  });

  it("reports the loaded count and pages on demand through the cursor, not a page number", async () => {
    const query = mockRows([makeApplication(), makeSoloApplication()], "cursor-2");
    mockDecide();

    render();

    expect(screen.getByText("2")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: /Load more/ }));
    expect(query.fetchNextPage).toHaveBeenCalledOnce();
  });

  it("warns that approving promotes the account, on the pending tab only", async () => {
    mockRows([makeApplication()]);
    mockDecide();

    render();
    expect(
      screen.getByText(/Approving promotes the account's role from Buyer to Agent/),
    ).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Approved" }));
    expect(
      screen.queryByText(/Approving promotes the account's role from Buyer to Agent/),
    ).not.toBeInTheDocument();
  });

  it("offers no decision buttons on a settled tab — the endpoint would only 409 — and shows when it was decided instead", async () => {
    mockRows([makeApplication()]);
    mockDecide();

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approved" }));

    // The status filter is what changed; the fixture rows are re-rendered under
    // it because the mocked hook ignores its argument.
    expect(screen.queryByRole("button", { name: /^Approve / })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /^Reject / })).not.toBeInTheDocument();
    expect(screen.getByText("Decided")).toBeInTheDocument();
  });

  it("re-filters the query by the selected status", async () => {
    mockRows([makeApplication()]);
    mockDecide();

    render();
    expect(vi.mocked(useApplications).mock.calls.at(-1)?.[0]).toBe("pending");

    await userEvent.click(screen.getByRole("button", { name: "Rejected" }));
    expect(vi.mocked(useApplications).mock.calls.at(-1)?.[0]).toBe("rejected");
  });

  it("names the group of status tabs and marks the selected one pressed", () => {
    mockRows([makeApplication()]);
    mockDecide();

    render();

    const tabs = screen.getByRole("group", { name: "Application status" });
    expect(within(tabs).getByRole("button", { name: "Pending" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    expect(within(tabs).getByRole("button", { name: "Approved" })).toHaveAttribute(
      "aria-pressed",
      "false",
    );
    // The order the server's three states are read in, and no counts on any of
    // them — the real numbers live on an endpoint this screen never calls.
    expect(within(tabs).getAllByRole("button").map((b) => b.textContent)).toEqual([
      "Pending",
      "Approved",
      "Rejected",
    ]);
    expect(screen.getByText("Newest accounts first")).toBeInTheDocument();
  });
});

describe("ApplicationsScreen — confirming a decision", () => {
  it("names the person and the consequence before granting agent access, and only then mutates", async () => {
    mockRows([makeApplication({ id: "user-9", fullName: "Otabek Yusupov" })]);
    const decide = mockDecide();

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));

    // Nothing has been sent yet: the dialog is the guard rail, not a receipt.
    expect(decide.mutate).not.toHaveBeenCalled();

    const dialog = screen.getByRole("dialog", { name: "Approve realtor application" });
    expect(dialog.textContent).toContain("otabek@lacasa.uz");
    expect(dialog.textContent).toContain("grants");
    expect(dialog.textContent).toContain("agent access to the platform");

    const confirm = within(dialog).getByRole("button", { name: "Approve" });
    // The irreversible treatment is quarantined to Reject — approving is a
    // grant, and a grant must not wear the colour that means "no way back".
    expect(confirm.className).not.toContain("containedError");
    // ...and the dialog never opens with the confirm button under the Enter key
    // that opened it.
    expect(confirm).not.toHaveFocus();

    await userEvent.click(confirm);
    expect(decide.mutate).toHaveBeenCalledWith(
      { userId: "user-9", decision: "approve" },
      expect.anything(),
    );
  });

  it("styles Reject as the irreversible confirmation and says the account stays a buyer", async () => {
    mockRows([makeApplication({ id: "user-9" })]);
    const decide = mockDecide();

    render();
    await userEvent.click(screen.getByRole("button", { name: "Reject Otabek Yusupov" }));

    const dialog = screen.getByRole("dialog", { name: "Reject realtor application" });
    expect(dialog.textContent).toContain("Their account stays a buyer");
    expect(dialog.textContent).toContain("cannot be reversed from here");

    const confirm = within(dialog).getByRole("button", { name: "Reject" });
    // `danger` is quarantined to irreversible confirmation on this surface, and
    // this is the one control on the screen entitled to it.
    expect(confirm.className).toContain("containedError");

    await userEvent.click(confirm);
    expect(decide.mutate).toHaveBeenCalledWith(
      { userId: "user-9", decision: "reject" },
      expect.anything(),
    );
  });

  it("cancels without touching the account", async () => {
    mockRows([makeApplication()]);
    const decide = mockDecide();

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await userEvent.click(
      within(screen.getByRole("dialog")).getByRole("button", { name: "Cancel" }),
    );

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    expect(decide.mutate).not.toHaveBeenCalled();
    // Cancelling always resets the mutation, so the next dialog cannot open
    // showing somebody else's failure.
    expect(decide.reset).toHaveBeenCalled();
  });

  it("shows a failed decision inside the dialog instead of closing it", async () => {
    mockRows([makeApplication()]);
    mockDecide({
      isError: true,
      error: new ApiError("internal", "Database is unavailable", 500),
    });

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));

    const dialog = screen.getByRole("dialog");
    expect(within(dialog).getByRole("alert").textContent).toContain("Database is unavailable");
  });
});

describe("ApplicationsScreen — another admin got there first", () => {
  it("closes the dialog and explains the 409 plainly rather than raising a failure", async () => {
    mockRows([makeApplication({ fullName: "Otabek Yusupov" })]);
    // The mutation reports the conflict through mutate()'s own onError, which is
    // where the screen decides between "explain it" and "keep the dialog open
    // with an error".
    const decide = mockDecide({
      mutate: vi.fn((_vars, handlers) => handlers.onError(alreadyDecidedError())),
    });

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await userEvent.click(
      within(screen.getByRole("dialog")).getByRole("button", { name: "Approve" }),
    );

    expect(decide.mutate).toHaveBeenCalledOnce();
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();

    const banner = screen.getByText(/was already decided by another admin/);
    expect(banner.textContent).toContain("Otabek Yusupov");
    expect(banner.textContent).toContain("nothing was changed");
    // Explicitly NOT an error: no alert anywhere, and none of the error palette.
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    expect(banner.closest("[role='status']")?.className).not.toContain("inline-banner--error");
  });

  it("clears the notice when the admin moves to another tab", async () => {
    mockRows([makeApplication()]);
    mockDecide({ mutate: vi.fn((_vars, handlers) => handlers.onError(alreadyDecidedError())) });

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await userEvent.click(
      within(screen.getByRole("dialog")).getByRole("button", { name: "Approve" }),
    );
    expect(screen.getByText(/was already decided by another admin/)).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: "Rejected" }));
    expect(screen.queryByText(/was already decided by another admin/)).not.toBeInTheDocument();
  });

  it("dismisses the notice on request, and only on request", async () => {
    mockRows([makeApplication()]);
    mockDecide({ mutate: vi.fn((_vars, handlers) => handlers.onError(alreadyDecidedError())) });

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await userEvent.click(
      within(screen.getByRole("dialog")).getByRole("button", { name: "Approve" }),
    );

    await userEvent.click(screen.getByRole("button", { name: "Dismiss" }));
    expect(screen.queryByText(/was already decided by another admin/)).not.toBeInTheDocument();
  });

  it("closes the dialog on a successful decision", async () => {
    mockRows([makeApplication()]);
    mockDecide({ mutate: vi.fn((_vars, handlers) => handlers.onSuccess()) });

    render();
    await userEvent.click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await userEvent.click(
      within(screen.getByRole("dialog")).getByRole("button", { name: "Approve" }),
    );

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    expect(screen.queryByText(/was already decided by another admin/)).not.toBeInTheDocument();
  });

  it("disables only the row being decided, so the rest of the queue stays workable", () => {
    mockRows([
      makeApplication({ id: "user-1", fullName: "Otabek Yusupov" }),
      makeSoloApplication({ id: "user-2", fullName: "Kamola Rashidova" }),
    ]);
    mockDecide({ isPending: true, variables: { userId: "user-1", decision: "approve" } });

    render();

    expect(screen.getByRole("button", { name: "Approve Otabek Yusupov" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Reject Otabek Yusupov" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Approve Kamola Rashidova" })).toBeEnabled();
  });
});
