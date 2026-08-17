/**
 * ApplicationsScreen.test — the review queue's UI, with its data layer
 * (`@/data/useApplications`) and its icon module (`@/ui/icons`) mocked.
 *
 * WHY THE HOOKS ARE MOCKED RATHER THAN A REAL QueryClientProvider MOUNTED:
 * @tanstack/react-query and @phosphor-icons/react both satisfy every
 * workspace's semver range with a single copy, so npm hoists them to the repo
 * ROOT — where their own `import "react"` resolves to apps/web's React 18,
 * while every file under apps/admin/src resolves to this app's nested React
 * 19. Two dispatchers in one tree, and rendering either package here dies
 * immediately: `QueryClientProvider` throws "Cannot read properties of null
 * (reading 'useEffect')" and a Phosphor glyph throws "Objects are not valid as
 * a React child". Both were verified in this workspace before this file was
 * written. `resolve.dedupe` in vitest.config.ts fixes react/react-dom for the
 * app's OWN modules but does not reach these externalized dependencies.
 * apps/console hit exactly this and mocks the same two modules; the request
 * side of the contract is covered instead by useApplications.test.ts, which
 * drives the real @lacasa/api-client over a faked Transport.
 *
 * The screen imports `isApplicationAlreadyDecided` from the same data module,
 * and that one is kept REAL (via importOriginal) — the 409 guard rail is the
 * behaviour under test here, and a mocked version of it would test nothing.
 */
import { act } from "react";
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "@lacasa/domain";
import { formatDateTime } from "@/lib/format";
import { useApplications, useDecideApplication } from "@/data/useApplications";
import { ApplicationsScreen } from "../ApplicationsScreen";
import { render } from "@/test/render";
import { makeApplication, makeSoloApplication, makePage } from "./fixtures";

vi.mock("@/data/useApplications", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/data/useApplications")>();
  return { ...actual, useApplications: vi.fn(), useDecideApplication: vi.fn() };
});

vi.mock("@/ui/icons", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/ui/icons")>();
  const FakeIcon = (props: Record<string, unknown>) => <svg data-testid="fake-icon" {...props} />;
  const faked = Object.fromEntries(Object.keys(actual).map((key) => [key, FakeIcon]));
  return { ...actual, ...faked };
});

type ApplicationsQuery = ReturnType<typeof useApplications>;
type DecideMutation = ReturnType<typeof useDecideApplication>;

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

async function click(element: Element) {
  // `act` imported from 'react' (which this file, living under apps/admin/src,
  // resolves to the correct nested copy) — @testing-library/user-event is
  // itself hoisted to the workspace root and cannot batch its updates against
  // this tree on its own. Same workaround as apps/console's suite.
  await act(async () => {
    await userEvent.click(element);
  });
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe("ApplicationsScreen — loading, empty and error states", () => {
  it("shows a six-row skeleton while the first page is in flight, and no applicant", () => {
    mockQuery({ isPending: true });
    mockDecide();

    const { container } = render(<ApplicationsScreen />);

    expect(container.querySelectorAll("tbody tr")).toHaveLength(6);
    expect(container.querySelector(".animate-pulse")).not.toBeNull();
    expect(screen.queryByText("Otabek Yusupov")).not.toBeInTheDocument();
  });

  it("says the queue is clear — not just 'no rows' — when nothing is pending", () => {
    mockRows([]);
    mockDecide();

    const { container } = render(<ApplicationsScreen />);

    expect(screen.getByText("The queue is clear")).toBeInTheDocument();
    expect(container.querySelectorAll("tbody tr")).toHaveLength(0);
  });

  it("surfaces the real error message and wires Try again to refetch()", async () => {
    const query = mockQuery({ isError: true, error: new Error("Network down") });
    mockDecide();

    render(<ApplicationsScreen />);

    expect(screen.getByText("Network down")).toBeInTheDocument();
    await click(screen.getByRole("button", { name: "Try again" }));
    expect(query.refetch).toHaveBeenCalledOnce();
  });

  it("keeps already-loaded rows on screen when a refresh fails, rather than blanking the queue", () => {
    mockQuery({
      data: { pages: [makePage([makeApplication()])], pageParams: [null] },
      isError: true,
      error: new Error("Network down"),
    });
    mockDecide();

    render(<ApplicationsScreen />);

    expect(screen.getByText("Otabek Yusupov")).toBeInTheDocument();
    expect(screen.getByText(/rows below are from the last successful load/)).toBeInTheDocument();
  });
});

describe("ApplicationsScreen — the queue", () => {
  it("renders the applicant, kind, agency, team size and applied-at from the row", () => {
    mockRows([makeApplication()]);
    mockDecide();

    render(<ApplicationsScreen />);

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

    render(<ApplicationsScreen />);

    expect(screen.getByText("Solo")).toBeInTheDocument();
    // Agency name and team size — two genuinely absent values on a solo row.
    expect(screen.getAllByText("—")).toHaveLength(2);
  });

  it("renders a row whose application block never arrived, instead of taking the whole app down with it", () => {
    // The endpoint filters on `realtorStatus` alone, while serializeUser.js
    // returns `realtor: null` for any row that never got a `realtorKind` —
    // two independent columns, as adminService.serializeApplicationRow's own
    // comment says. @lacasa/api-client types the field non-null, so only a
    // cast can express what the wire really sends. This is not hypothetical:
    // apps/api/prisma/seed.js creates agent@lacasa.dev with no kind and
    // seed-olx.js then sets its status to APPROVED, so a seeded database
    // serves exactly this row on the Approved tab — and reading `.kind` off
    // it threw a TypeError with no error boundary above to catch it.
    const withoutApplication = {
      ...makeApplication(),
      realtor: null,
    } as unknown as ReturnType<typeof makeApplication>;
    mockRows([withoutApplication]);
    mockDecide();

    render(<ApplicationsScreen />);

    expect(screen.getByText("Otabek Yusupov")).toBeInTheDocument();
    // Kind, agency name, team size and applied-at: four facts the payload
    // carries nothing for, every one of them reported absent, none invented.
    expect(screen.getAllByText("—")).toHaveLength(4);
  });

  it("reports the loaded count and pages on demand through the cursor, not a page number", async () => {
    const query = mockRows([makeApplication(), makeSoloApplication()], "cursor-2");
    mockDecide();

    render(<ApplicationsScreen />);

    expect(screen.getByText("2")).toBeInTheDocument();
    await click(screen.getByRole("button", { name: /Load more/ }));
    expect(query.fetchNextPage).toHaveBeenCalledOnce();
  });

  it("warns that approving promotes the account, on the pending tab only", async () => {
    mockRows([makeApplication()]);
    mockDecide();

    render(<ApplicationsScreen />);
    expect(
      screen.getByText(/Approving promotes the account's role from Buyer to Agent/),
    ).toBeInTheDocument();

    await click(screen.getByRole("button", { name: "Approved" }));
    expect(
      screen.queryByText(/Approving promotes the account's role from Buyer to Agent/),
    ).not.toBeInTheDocument();
  });

  it("offers no decision buttons on a settled tab — the endpoint would only 409 — and shows when it was decided instead", async () => {
    mockRows([makeApplication()]);
    mockDecide();

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Approved" }));

    // The status filter is what changed; the fixture rows are re-rendered
    // under it because the mocked hook ignores its argument.
    expect(screen.queryByRole("button", { name: /^Approve / })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /^Reject / })).not.toBeInTheDocument();
    expect(screen.getByText("Decided")).toBeInTheDocument();
  });

  it("re-filters the query by the selected status", async () => {
    mockRows([makeApplication()]);
    mockDecide();

    render(<ApplicationsScreen />);
    expect(vi.mocked(useApplications).mock.calls.at(-1)?.[0]).toBe("pending");

    await click(screen.getByRole("button", { name: "Rejected" }));
    expect(vi.mocked(useApplications).mock.calls.at(-1)?.[0]).toBe("rejected");
  });
});

describe("ApplicationsScreen — confirming a decision", () => {
  it("names the person and the consequence before granting agent access, and only then mutates", async () => {
    mockRows([makeApplication({ id: "user-9", fullName: "Otabek Yusupov" })]);
    const decide = mockDecide();

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));

    // Nothing has been sent yet: the dialog is the guard rail, not a receipt.
    expect(decide.mutate).not.toHaveBeenCalled();

    const dialog = screen.getByRole("dialog", { name: "Approve realtor application" });
    expect(dialog.textContent).toContain("otabek@lacasa.uz");
    expect(dialog.textContent).toContain("grants");
    expect(dialog.textContent).toContain("agent access to the platform");

    await click(within(dialog).getByRole("button", { name: "Approve" }));
    expect(decide.mutate).toHaveBeenCalledWith(
      { userId: "user-9", decision: "approve" },
      expect.anything(),
    );
  });

  it("styles Reject as the destructive confirmation and says the account stays a buyer", async () => {
    mockRows([makeApplication({ id: "user-9" })]);
    const decide = mockDecide();

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Reject Otabek Yusupov" }));

    const dialog = screen.getByRole("dialog", { name: "Reject realtor application" });
    expect(dialog.textContent).toContain("Their account stays a buyer");

    const confirm = within(dialog).getByRole("button", { name: "Reject" });
    // `danger` (magenta) is quarantined to irreversible confirmation on this
    // surface — this is the one control on the screen entitled to it.
    expect(confirm.className).toContain("border-danger");

    await click(confirm);
    expect(decide.mutate).toHaveBeenCalledWith(
      { userId: "user-9", decision: "reject" },
      expect.anything(),
    );
  });

  it("cancels without touching the account", async () => {
    mockRows([makeApplication()]);
    const decide = mockDecide();

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await click(
      within(screen.getByRole("dialog")).getByRole("button", { name: "Cancel" }),
    );

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    expect(decide.mutate).not.toHaveBeenCalled();
  });

  it("shows a failed decision inside the dialog instead of closing it", async () => {
    mockRows([makeApplication()]);
    mockDecide({
      isError: true,
      error: new ApiError("internal", "Database is unavailable", 500),
    });

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));

    const dialog = screen.getByRole("dialog");
    expect(within(dialog).getByRole("alert").textContent).toContain("Database is unavailable");
  });
});

describe("ApplicationsScreen — another admin got there first", () => {
  it("closes the dialog and explains the 409 plainly rather than raising a failure", async () => {
    mockRows([makeApplication({ fullName: "Otabek Yusupov" })]);
    // The mutation reports the conflict through mutate()'s own onError, which
    // is where the screen decides between "explain it" and "keep the dialog
    // open with an error".
    const decide = mockDecide({
      mutate: vi.fn((_vars, handlers) => handlers.onError(alreadyDecidedError())),
    });

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await click(within(screen.getByRole("dialog")).getByRole("button", { name: "Approve" }));

    expect(decide.mutate).toHaveBeenCalledOnce();
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();

    const banner = screen.getByText(/was already decided by another admin/);
    expect(banner.textContent).toContain("Otabek Yusupov");
    expect(banner.textContent).toContain("nothing was changed");
    // Explicitly NOT an error: no alert, and none of the error palette.
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    expect(banner.closest("[role='status']")?.className).not.toContain("err");
  });

  it("clears the notice when the admin moves to another tab", async () => {
    mockRows([makeApplication()]);
    mockDecide({ mutate: vi.fn((_vars, handlers) => handlers.onError(alreadyDecidedError())) });

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await click(within(screen.getByRole("dialog")).getByRole("button", { name: "Approve" }));
    expect(screen.getByText(/was already decided by another admin/)).toBeInTheDocument();

    await click(screen.getByRole("button", { name: "Rejected" }));
    expect(screen.queryByText(/was already decided by another admin/)).not.toBeInTheDocument();
  });

  it("closes the dialog on a successful decision", async () => {
    mockRows([makeApplication()]);
    mockDecide({ mutate: vi.fn((_vars, handlers) => handlers.onSuccess()) });

    render(<ApplicationsScreen />);
    await click(screen.getByRole("button", { name: "Approve Otabek Yusupov" }));
    await click(within(screen.getByRole("dialog")).getByRole("button", { name: "Approve" }));

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    expect(screen.queryByText(/was already decided by another admin/)).not.toBeInTheDocument();
  });

  it("disables only the row being decided, so the rest of the queue stays workable", () => {
    mockRows([
      makeApplication({ id: "user-1", fullName: "Otabek Yusupov" }),
      makeSoloApplication({ id: "user-2", fullName: "Kamola Rashidova" }),
    ]);
    mockDecide({ isPending: true, variables: { userId: "user-1", decision: "approve" } });

    render(<ApplicationsScreen />);

    expect(screen.getByRole("button", { name: "Approve Otabek Yusupov" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Approve Kamola Rashidova" })).toBeEnabled();
  });
});
