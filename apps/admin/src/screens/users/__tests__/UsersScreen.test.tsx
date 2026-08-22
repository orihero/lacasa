/**
 * UsersScreen.test — the real screen and the real `@/data/useUsers` hook,
 * mounted over the real @lacasa/api-client with a faked Transport underneath.
 *
 * WHY A TRANSPORT DOUBLE RATHER THAN A MOCK OF `@/data/useUsers`
 * (apps/console/src/screens/leads/__tests__ mocks its data hook): the double
 * is the same shape as packages/api-client/src/testing/fakeTransport.ts's —
 * record every TransportRequest, answer it from the test — only routed by
 * method, so these tests also pin the half of the contract a hook mock erases.
 * That the directory really is `GET /admin/users` with `q`/`role`/`limit` on
 * the query string, that paging really passes the server's opaque cursor back
 * untouched, and that the role change really is
 * `PATCH /admin/users/:id/role` with `{ role }` as its body are exactly the
 * facts that break silently when a resource is renamed.
 *
 * REAL @tanstack/react-query, REAL @/ui/icons. The deleted app's suite faked
 * both, but only to work around a React 18/19 hoisting split in that
 * workspace — an environment workaround, not behaviour worth reproducing.
 * This app is on React 18 with exactly one React in the tree, so the query
 * library's own retry, invalidation-prefix and infinite-page semantics are
 * what these tests run against.
 */
import { act, fireEvent, screen, waitFor, within } from "@testing-library/react";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import type { AdminPage, AdminUserRow, TransportRequest } from "@lacasa/api-client";
import { ApiError, type ErrorCode } from "@lacasa/domain";
import i18n from "@/i18n";
import { createTestQueryClient, renderWithProviders } from "@/test/render";
import { UsersScreen } from "../UsersScreen";

/**
 * Shared between the test body and the module factory below, which vitest
 * hoists above every import in this file — `vi.hoisted` is what lets both
 * sides reach the same object.
 */
const wire = vi.hoisted(() => ({
  calls: [] as TransportRequest[],
  respond(req: TransportRequest): unknown {
    throw new Error(`no responder set for ${req.method} ${req.url}`);
  },
}));

vi.mock("@/lib/apiClient", async () => {
  const { createLaCasaApiClient } = await import("@lacasa/api-client");
  return {
    API_BASE_URL: "http://admin.test/api",
    localStorageTokenStorage: {
      getToken: () => Promise.resolve("test-token"),
      setToken: () => Promise.resolve(),
    },
    apiClient: createLaCasaApiClient({
      transport: {
        request<T>(req: TransportRequest): Promise<T> {
          wire.calls.push(req);
          // Answered in a microtask so a responder that throws rejects the
          // promise rather than throwing synchronously into the caller.
          return Promise.resolve().then(() => wire.respond(req) as T);
        },
      },
      tokenStorage: {
        getToken: () => Promise.resolve("test-token"),
        setToken: () => Promise.resolve(),
      },
      baseUrl: "http://admin.test/api",
    }),
  };
});

// ---------------------------------------------------------------------------
// Fixtures

const AGENT: AdminUserRow = {
  id: "a3f21e08-1c44-4b0e-9f21-3d6b0e5a71c2",
  fullName: "Javlon Rustamov",
  email: "javlon@lacasa.uz",
  phoneNumber: "+998901112233",
  role: "agent",
  avatar: null,
  agentId: null,
  realtor: {
    kind: "agency",
    status: "approved",
    agencyName: "Rustamov Realty",
    officePhone: "+998712001122",
    teamSize: "six_to_fifteen",
    appliedAt: "2026-03-10T08:00:00.000Z",
    decidedAt: "2026-03-12T08:00:00.000Z",
  },
  createdAt: "2026-03-14T09:00:00.000Z",
  counts: { ads: 24, leads: 12 },
};

/**
 * A buyer who never applied. serializeUser sends `realtor: null` for these,
 * which is the case the "Realtor status" column must not turn into a "None"
 * badge the payload cannot back up.
 */
const BUYER: AdminUserRow = {
  id: "f8c30b51-7e2a-4a11-8c39-1b7d2f9c0a55",
  fullName: "Dilnoza Yusupova",
  email: "dilnoza@gmail.com",
  phoneNumber: null,
  role: "user",
  avatar: null,
  agentId: null,
  realtor: null,
  createdAt: "2026-08-03T11:42:00.000Z",
  counts: { ads: 0, leads: 0 },
};

function usersPage(
  items: AdminUserRow[],
  nextCursor: string | null = null,
): AdminPage<AdminUserRow> {
  return { items, nextCursor };
}

// ---------------------------------------------------------------------------
// Harness

const getCalls = (method: TransportRequest["method"]) =>
  wire.calls.filter((call) => call.method === method);

/**
 * The nth recorded call of a method, or a failure naming what was missing.
 * `noUncheckedIndexedAccess` is on in this workspace, so an inline
 * `getCalls("GET")[1]` would need a non-null assertion at every use — and an
 * assertion that turned out wrong would surface as "cannot read properties of
 * undefined" instead of "the filter change never fired a request".
 */
function callAt(method: TransportRequest["method"], index: number): TransportRequest {
  const call = getCalls(method)[index];
  if (!call) {
    throw new Error(
      `expected at least ${index + 1} ${method} request(s), saw ${getCalls(method).length}`,
    );
  }
  return call;
}

/**
 * The three guard-rail codes are NOT members of @lacasa/domain's ERROR_CODES
 * — that list predates the admin router — so `ApiError`'s own `code` type has
 * to be widened to construct the errors the server genuinely sends. The cast
 * is this test admitting to the same gap roleChangeCopy's `errorCode` works
 * around.
 */
function apiError(code: string, message: string, status: number): ApiError {
  return new ApiError(code as ErrorCode, message, status);
}

function mount(queryClient = createTestQueryClient()) {
  // withAuth: false — this screen reads no session, and mounting the real
  // AuthProvider would put its own GET /auth/me at the head of wire.calls.
  return renderWithProviders(<UsersScreen />, { withAuth: false, queryClient });
}

async function openRoleDialog(fullName: string): Promise<HTMLElement> {
  fireEvent.click(screen.getByRole("button", { name: `Change role for ${fullName}` }));
  return screen.findByRole("dialog");
}

/**
 * The footer's running count, reassembled: LoadMore renders the number in its
 * own element, so the sentence is spread across three text nodes.
 */
function footerCount(): string {
  return screen.getByText(/accounts/, { selector: ".load-more__count" }).textContent ?? "";
}

function rowFor(fullName: string): HTMLElement {
  const row = screen.getByText(fullName).closest("tr");
  if (!row) throw new Error(`no row rendered for ${fullName}`);
  return row;
}

beforeAll(async () => {
  await i18n.changeLanguage("en");
});

beforeEach(() => {
  wire.calls.length = 0;
  wire.respond = () => usersPage([AGENT, BUYER]);
});

// ---------------------------------------------------------------------------

describe("UsersScreen", () => {
  it("lists accounts with their role, realtor status, counts and joined date", async () => {
    mount();
    await screen.findByText("Javlon Rustamov");

    const listCall = callAt("GET", 0);
    expect(getCalls("GET")).toHaveLength(1);
    expect(listCall.url).toBe("http://admin.test/api/admin/users");
    expect(listCall.query?.limit).toBe(50);
    // No filter is active on first paint, and "no filter" has to be an absent
    // query key rather than an empty one.
    expect(listCall.query?.q).toBeUndefined();
    expect(listCall.query?.role).toBeUndefined();
    expect(listCall.query?.realtorStatus).toBeUndefined();
    expect(listCall.query?.cursor).toBeUndefined();

    const agentRow = rowFor("Javlon Rustamov");
    expect(within(agentRow).getByText("javlon@lacasa.uz")).toBeTruthy();
    expect(within(agentRow).getByText("Agent")).toBeTruthy();
    expect(within(agentRow).getByText("Approved")).toBeTruthy();
    expect(within(agentRow).getByText("24")).toBeTruthy();
    expect(within(agentRow).getByText("12")).toBeTruthy();
    expect(within(agentRow).getByText("14.03.2026")).toBeTruthy();
    expect(within(agentRow).getByText("a3f21e08…")).toBeTruthy();
    // The full id is still reachable, for the cross-reference the prefix is
    // only a handle for.
    expect(within(agentRow).getByText("a3f21e08…").getAttribute("title")).toBe(AGENT.id);

    const buyerRow = rowFor("Dilnoza Yusupova");
    expect(within(buyerRow).getByText("Buyer")).toBeTruthy();
    // `realtor: null` is not `realtorStatus: "none"`, so the cell says
    // "no value" rather than inventing a status the payload does not carry.
    expect(within(buyerRow).getByText("—")).toBeTruthy();
    expect(within(buyerRow).queryByText("None")).toBeNull();

    // Keyset paging with no cursor left: an end marker, never a page number.
    expect(screen.getByText("End of list")).toBeTruthy();
    // "2 accounts" with nothing left to fetch and "2 accounts loaded" with
    // more behind it are different facts. No total is shown — the endpoint
    // does not return one and the footer must never invent it.
    expect(footerCount()).toBe("2 accounts");
  });

  it("exposes the toolbar as three named, pick-one controls", async () => {
    mount();
    await screen.findByText("Javlon Rustamov");

    // A real group with real buttons, so a screen-reader user is told which of
    // the filters they have landed in and which option is on.
    const group = screen.getByRole("group", { name: "Role" });
    expect(
      within(group)
        .getAllByRole("button")
        .map((button) => button.textContent),
    ).toEqual(["All", "Buyer", "Agent", "Coworker", "Admin"]);
    expect(within(group).getByRole("button", { name: "All" }).getAttribute("aria-pressed")).toBe(
      "true",
    );

    const box = screen.getByLabelText("Search users");
    expect(box.getAttribute("type")).toBe("search");
    expect(box.getAttribute("placeholder")).toBe("Search name or email…");

    const select = screen.getByLabelText("Realtor status") as HTMLSelectElement;
    expect(Array.from(select.options).map((option) => option.value)).toEqual([
      "all",
      "none",
      "pending",
      "approved",
      "rejected",
    ]);
    expect(Array.from(select.options).map((option) => option.text)).toEqual([
      "Any realtor status",
      "None",
      "Pending",
      "Approved",
      "Rejected",
    ]);
    expect(select.value).toBe("all");

    // The avatar fallback announces the person rather than announcing nothing.
    expect(within(rowFor("Javlon Rustamov")).getByRole("img")).toHaveAttribute(
      "aria-label",
      "Javlon Rustamov",
    );
  });

  it("shows the table's own skeleton while a page is pending, and no footer", async () => {
    // The first load, caught before the transport's microtask resolves.
    mount();
    expect(screen.getAllByRole("columnheader")).toHaveLength(8);
    expect(document.querySelectorAll(".MuiSkeleton-root")).toHaveLength(8 * 8);
    expect(screen.queryByText("End of list")).toBeNull();
    expect(screen.queryByRole("alert")).toBeNull();

    await screen.findByText("Javlon Rustamov");
    expect(document.querySelectorAll(".MuiSkeleton-root")).toHaveLength(0);
  });

  it("drops to the skeleton on a filter change rather than holding the old rows", async () => {
    mount();
    await screen.findByText("Javlon Rustamov");

    // Every filter combination is its own cache entry and there is no
    // `placeholderData: keepPreviousData` — showing the last filter's rows
    // under the new filter's controls is how an admin acts on the wrong row.
    wire.respond = () => new Promise(() => {});
    fireEvent.click(screen.getByRole("button", { name: "Coworker" }));

    await waitFor(() =>
      expect(document.querySelectorAll(".MuiSkeleton-root")).toHaveLength(8 * 8),
    );
    expect(screen.queryByText("Javlon Rustamov")).toBeNull();
  });

  it("names the row action after the account it would change", async () => {
    mount();
    await screen.findByText("Javlon Rustamov");

    // Four identical "Change role" buttons in a 50-row table are four buttons
    // a screen-reader user cannot tell apart, on the one control here that
    // changes someone's access.
    expect(screen.getByRole("button", { name: "Change role for Javlon Rustamov" })).toBeTruthy();
    expect(screen.getByRole("button", { name: "Change role for Dilnoza Yusupova" })).toBeTruthy();
  });

  it("states that the order is structural and offers no control that could change it", async () => {
    mount();
    await screen.findByText("Javlon Rustamov");

    expect(screen.getByText("Newest accounts first")).toBeTruthy();
    // Deliberate absences: keyset paging fixes the order, and this screen has
    // no refresh of its own (PRECEDENCE.md).
    expect(screen.queryByRole("button", { name: "Refresh" })).toBeNull();
    expect(screen.queryByRole("columnheader", { name: "Plan" })).toBeNull();
  });

  it("pages with the cursor the server handed back, never a constructed one", async () => {
    wire.respond = (req) =>
      req.query?.cursor === "cursor-1"
        ? usersPage([
            { ...AGENT, id: "c0ffee00-0000-4000-8000-000000000001", fullName: "Kamola Rashidova" },
          ])
        : usersPage([AGENT, BUYER], "cursor-1");

    mount();
    await screen.findByText("Javlon Rustamov");
    // More pages behind it, so the count says so.
    expect(footerCount()).toBe("2 accounts loaded");

    fireEvent.click(screen.getByRole("button", { name: /Load more/ }));
    await screen.findByText("Kamola Rashidova");

    expect(callAt("GET", 1).query?.cursor).toBe("cursor-1");
    // Appended, not replaced.
    expect(screen.getByText("Javlon Rustamov")).toBeTruthy();
  });

  it("shows the database-is-empty message when nothing is filtered away", async () => {
    wire.respond = () => usersPage([]);
    mount();

    expect(await screen.findByText("No accounts yet")).toBeTruthy();
    expect(screen.getByText(/check the environment strip/)).toBeTruthy();
  });

  it("distinguishes a filtered-away list from an empty one", async () => {
    mount();
    await screen.findByText("Javlon Rustamov");

    wire.respond = () => usersPage([]);
    fireEvent.click(screen.getByRole("button", { name: "Coworker" }));

    expect(await screen.findByText("No accounts match these filters")).toBeTruthy();
    expect(screen.queryByText("No accounts yet")).toBeNull();
    expect(
      screen.getByText("No account on the platform has this combination of role and realtor status."),
    ).toBeTruthy();
    expect(callAt("GET", 1).query?.role).toBe("coworker");
  });

  it("filters by realtor status server-side", async () => {
    mount();
    await screen.findByText("Javlon Rustamov");

    fireEvent.change(screen.getByLabelText("Realtor status"), { target: { value: "pending" } });

    await waitFor(() => expect(getCalls("GET")).toHaveLength(2));
    expect(callAt("GET", 1).query?.realtorStatus).toBe("pending");
  });

  it("surfaces a failed list with the API's own message and a retry", async () => {
    wire.respond = () => {
      throw apiError("internal", "Database connection lost", 500);
    };
    mount();

    const alert = await screen.findByRole("alert");
    // The server's real words and the machine code an admin can act on —
    // never a house phrase, on the screen that changes people's access.
    expect(within(alert).getByText("Database connection lost")).toBeTruthy();
    expect(within(alert).getByText("internal")).toBeTruthy();

    wire.respond = () => usersPage([AGENT, BUYER]);
    fireEvent.click(screen.getByRole("button", { name: "Try again" }));

    expect(await screen.findByText("Javlon Rustamov")).toBeTruthy();
  });

  it("keeps the rows and still states the failure when a later read fails", async () => {
    wire.respond = (req) =>
      req.query?.cursor === "cursor-1"
        ? (() => {
            throw apiError("internal", "Database connection lost", 500);
          })()
        : usersPage([AGENT, BUYER], "cursor-1");

    mount();
    await screen.findByText("Javlon Rustamov");

    fireEvent.click(screen.getByRole("button", { name: /Load more/ }));

    // Without this line a failed "Load more" would look exactly like reaching
    // the end of the directory.
    const strip = await screen.findByRole("alert");
    expect(strip.textContent).toBe(
      "Could not read the directory: Database connection lost. The rows above are from the last successful load.",
    );
    expect(screen.getByText("Javlon Rustamov")).toBeTruthy();
  });

  it("debounces the search box instead of querying per keystroke", async () => {
    vi.useFakeTimers();
    try {
      mount();
      await flush();
      expect(getCalls("GET")).toHaveLength(1);

      const box = screen.getByLabelText("Search users");
      // The server rejects a `q` over 200 characters, so a pasted wall of text
      // is truncated client-side rather than becoming a 400 to decode.
      expect(box.getAttribute("maxlength")).toBe("200");

      fireEvent.change(box, { target: { value: "k" } });
      fireEvent.change(box, { target: { value: "ka" } });
      fireEvent.change(box, { target: { value: "kam" } });
      await flush();

      // Three keystrokes inside the debounce window are still zero requests.
      expect(getCalls("GET")).toHaveLength(1);

      act(() => {
        vi.advanceTimersByTime(300);
      });
      await flush();

      expect(getCalls("GET")).toHaveLength(2);
      expect(callAt("GET", 1).query?.q).toBe("kam");

      // The debounce watches the TRIMMED value, so a trailing space after a
      // settled term asks the database nothing new.
      fireEvent.change(box, { target: { value: "kam " } });
      act(() => {
        vi.advanceTimersByTime(300);
      });
      await flush();
      expect(getCalls("GET")).toHaveLength(2);
    } finally {
      vi.useRealTimers();
    }
  });

  describe("changing a role", () => {
    it("never writes without a confirmation", async () => {
      mount();
      await screen.findByText("Javlon Rustamov");

      const dialog = await openRoleDialog("Javlon Rustamov");
      expect(getCalls("PATCH")).toHaveLength(0);
      expect(dialog.getAttribute("aria-modal")).toBe("true");
      expect(within(dialog).getByRole("heading", { level: 3 }).textContent).toBe("Change role");
      // The record being acted on is restated in full, id and all: a prefix is
      // not proof of identity.
      expect(within(dialog).getByText(AGENT.id)).toBeTruthy();
      expect(within(dialog).getByRole("button", { name: "Close" })).toBeTruthy();
      // The option for the role the account already holds says so.
      expect(within(dialog).getByRole("option", { name: "Agent (current)" })).toBeTruthy();

      fireEvent.click(within(dialog).getByRole("button", { name: "Cancel" }));

      await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());
      expect(getCalls("PATCH")).toHaveLength(0);
    });

    it("refuses to submit a change to the role the account already holds", async () => {
      mount();
      await screen.findByText("Javlon Rustamov");

      const dialog = await openRoleDialog("Javlon Rustamov");
      fireEvent.click(within(dialog).getByRole("button", { name: "Change to Agent" }));

      expect(await within(dialog).findByText(/already has/)).toBeTruthy();
      expect(getCalls("PATCH")).toHaveLength(0);
    });

    it("gives promotion to admin the strongest confirmation on the screen", async () => {
      mount();
      await screen.findByText("Dilnoza Yusupova");

      const dialog = await openRoleDialog("Dilnoza Yusupova");
      fireEvent.change(within(dialog).getByLabelText("New role"), { target: { value: "admin" } });

      expect(
        within(dialog).getByText("This is the strongest permission the platform has."),
      ).toBeTruthy();
      expect(within(dialog).getByText(/change anyone's role — including yours/)).toBeTruthy();
      // The confirm button names the power being handed over instead of
      // reading "Change role" like every reversible transition does.
      expect(within(dialog).getByRole("button", { name: "Grant admin access" })).toBeTruthy();
    });

    it("explains what a demotion does and does not take with it", async () => {
      mount();
      await screen.findByText("Javlon Rustamov");

      const dialog = await openRoleDialog("Javlon Rustamov");
      fireEvent.change(within(dialog).getByLabelText("New role"), { target: { value: "user" } });

      // Quoted off the row itself, so the reassurance is checkable.
      expect(within(dialog).getByText(/24 ads and 12 leads/)).toBeTruthy();
      expect(within(dialog).getByText(/Nothing is deleted/)).toBeTruthy();

      // An account that owns nothing gets the shorter sentence instead of
      // "0 ads and 0 leads stay put".
      fireEvent.click(within(dialog).getByRole("button", { name: "Cancel" }));
      await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());

      const buyerDialog = await openRoleDialog("Dilnoza Yusupova");
      fireEvent.change(within(buyerDialog).getByLabelText("New role"), {
        target: { value: "agent" },
      });
      fireEvent.change(within(buyerDialog).getByLabelText("New role"), {
        target: { value: "user" },
      });
      expect(within(buyerDialog).queryByText(/Nothing is deleted/)).toBeNull();
    });

    it("sends the change, closes, and re-reads the list rather than patching it", async () => {
      const queryClient = createTestQueryClient();
      const invalidate = vi.spyOn(queryClient, "invalidateQueries");
      mount(queryClient);
      await screen.findByText("Javlon Rustamov");

      wire.respond = (req) => {
        if (req.method === "PATCH") return { user: { ...AGENT, role: "admin" } };
        return usersPage([{ ...AGENT, role: "admin" }, BUYER]);
      };

      const dialog = await openRoleDialog("Javlon Rustamov");
      fireEvent.change(within(dialog).getByLabelText("New role"), { target: { value: "admin" } });
      fireEvent.click(within(dialog).getByRole("button", { name: "Grant admin access" }));

      await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());

      const patch = callAt("PATCH", 0);
      expect(patch.url).toBe(`http://admin.test/api/admin/users/${AGENT.id}/role`);
      expect(patch.body).toEqual({ role: "admin" });

      // Both the directory and the overview's per-role counts go stale — and
      // nothing else: the applications list carries no role to go stale.
      expect(invalidate.mock.calls.map((call) => call[0])).toEqual([
        { queryKey: ["users"] },
        { queryKey: ["overview"] },
      ]);

      await waitFor(() => expect(getCalls("GET").length).toBeGreaterThan(1));
      await waitFor(() =>
        expect(within(rowFor("Javlon Rustamov")).getByText("Admin")).toBeTruthy(),
      );
    });

    it.each([
      {
        code: "self_demotion",
        status: 400,
        role: "user",
        subject: "Javlon Rustamov",
        expected: /cannot remove your own admin access/,
      },
      {
        code: "last_admin",
        status: 409,
        role: "user",
        subject: "Javlon Rustamov",
        expected: /only admin account left/,
      },
      {
        code: "coworker_needs_agent",
        status: 400,
        role: "coworker",
        subject: "Dilnoza Yusupova",
        expected: /coworker must belong to an agent/,
      },
    ])(
      "turns the $code guard rail into its own sentence",
      async ({ code, status, role, subject, expected }) => {
        mount();
        await screen.findByText(subject);

        wire.respond = (req) => {
          if (req.method === "PATCH") throw apiError(code, "server prose nobody reads", status);
          return usersPage([AGENT, BUYER]);
        };

        const dialog = await openRoleDialog(subject);
        fireEvent.change(within(dialog).getByLabelText("New role"), { target: { value: role } });
        fireEvent.click(within(dialog).getByRole("button", { name: /^Change to / }));

        expect(await within(dialog).findByText(expected)).toBeTruthy();
        // The dialog stays open on a refusal: each of these is something the
        // admin can act on without losing their place.
        expect(screen.queryByRole("dialog")).not.toBeNull();
        // Never the server's raw prose, and never a generic failure line.
        expect(within(dialog).queryByText("server prose nobody reads")).toBeNull();
      },
    );

    it("does not carry one row's refusal into the next row's dialog", async () => {
      mount();
      await screen.findByText("Javlon Rustamov");

      wire.respond = (req) => {
        if (req.method === "PATCH") throw apiError("last_admin", "last admin", 409);
        return usersPage([AGENT, BUYER]);
      };

      const first = await openRoleDialog("Javlon Rustamov");
      fireEvent.change(within(first).getByLabelText("New role"), { target: { value: "user" } });
      fireEvent.click(within(first).getByRole("button", { name: "Change to Buyer" }));
      expect(await within(first).findByText(/only admin account left/)).toBeTruthy();

      fireEvent.click(within(first).getByRole("button", { name: "Cancel" }));
      await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());

      // A `last_admin` message still on screen while a different account's
      // dialog is open would read as a refusal of THIS change.
      const second = await openRoleDialog("Dilnoza Yusupova");
      expect(within(second).queryByText(/only admin account left/)).toBeNull();
    });
  });
});

/**
 * Under fake timers nothing drains on its own: react-query schedules its
 * notifications with `setTimeout(cb, 0)` and the transport answers in a
 * microtask, so a pass has to do both. Only the debounce test needs this —
 * every other test uses RTL's real-timer `findBy*`/`waitFor`.
 */
async function flush(passes = 10): Promise<void> {
  for (let i = 0; i < passes; i += 1) {
    await act(async () => {
      await Promise.resolve();
      await Promise.resolve();
      vi.advanceTimersByTime(0);
    });
  }
}
