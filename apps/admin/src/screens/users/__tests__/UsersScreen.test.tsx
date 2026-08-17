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
 * WHY `@tanstack/react-query` AND `@/ui/icons` ARE FAKED ANYWAY — the same
 * React 18/19 hoisting split src/test/render.tsx documents, reaching one layer
 * further out. Both packages are hoisted to the *workspace root*
 * (node_modules/@tanstack/react-query, node_modules/@phosphor-icons/react)
 * while this app keeps its own nested React 19; vitest externalises anything
 * under node_modules, so it is loaded by Node's own resolution and
 * vitest.config.ts's `resolve.dedupe` — which only governs modules Vite
 * transforms — never reaches it. The result is that react-query's internals
 * call the ROOT react@18.3.1's `useEffect` while the tree is being rendered by
 * this app's react-dom@19.2.3, and React 18's dispatcher is null:
 *
 *     TypeError: Cannot read properties of null (reading 'useEffect')
 *       ❯ QueryClientProvider .../@tanstack/react-query/src/QueryClientProvider.tsx:33
 *
 * This is a TEST-ONLY failure — `vite dev`/`vite build` transform and dedupe
 * the same imports, so the browser gets one React — and the fix belongs in
 * apps/admin/vitest.config.ts (`test.server.deps.inline` for those two
 * packages), which this screen does not own. Until then the three react-query
 * hooks `@/data/useUsers` actually uses are re-implemented below against THIS
 * app's React: small enough to read in one screen, and they keep every line
 * of the hook under test — parameter normalisation, cursor handling, the
 * invalidation keys — genuinely executing.
 */
import { act } from "react";
import { fireEvent, screen, within } from "@testing-library/dom";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AdminPage, AdminUserRow, TransportRequest } from "@lacasa/api-client";
import { ApiError, type ErrorCode } from "@lacasa/domain";
import { render } from "@/test/render";
import { UsersScreen } from "../UsersScreen";

/**
 * Shared between the test body and the module factories below, which vitest
 * hoists above every import in this file — `vi.hoisted` is what lets both
 * sides reach the same object.
 */
const wire = vi.hoisted(() => ({
  calls: [] as TransportRequest[],
  respond(req: TransportRequest): unknown {
    throw new Error(`no responder set for ${req.method} ${req.url}`);
  },
  /** Every `queryClient.invalidateQueries` argument the mutation passed. */
  invalidated: [] as unknown[],
  /** Refetch callbacks of the mounted list, so an invalidation can fire them. */
  refetchers: new Set<() => void>(),
}));

vi.mock("@/lib/apiClient", async () => {
  const { createLaCasaApiClient } = await import("@lacasa/api-client");
  return {
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

vi.mock("@tanstack/react-query", async () => {
  const { useCallback, useEffect, useRef, useState } = await import("react");

  interface Page {
    items: unknown[];
    nextCursor: string | null;
  }
  interface InfiniteOptions {
    queryKey: readonly unknown[];
    queryFn: (ctx: { pageParam: string | undefined }) => Promise<Page>;
    initialPageParam: string | undefined;
    getNextPageParam: (page: Page) => string | undefined;
  }
  interface MutationOptions<V> {
    mutationFn: (variables: V) => Promise<unknown>;
    onSuccess?: (data: unknown, variables: V) => void;
  }
  type Status = "pending" | "success" | "error";

  function useInfiniteQuery(options: InfiniteOptions) {
    const [pages, setPages] = useState<Page[]>([]);
    const [status, setStatus] = useState<Status>("pending");
    const [error, setError] = useState<unknown>(null);
    const [fetchingNext, setFetchingNext] = useState(false);
    const [nonce, setNonce] = useState(0);
    const pagesRef = useRef<Page[]>(pages);
    pagesRef.current = pages;

    // Serialised, not the array itself: the screen builds a fresh key object
    // on every render, so an identity comparison would refetch forever.
    const key = JSON.stringify(options.queryKey);
    // The options object is likewise rebuilt each render; the key and the
    // refetch nonce are the only things that should restart a fetch.
    useEffect(() => {
      let cancelled = false;
      setStatus("pending");
      setPages([]);
      setError(null);
      options.queryFn({ pageParam: options.initialPageParam }).then(
        (page) => {
          if (cancelled) return;
          setPages([page]);
          setStatus("success");
        },
        (failure) => {
          if (cancelled) return;
          setError(failure);
          setStatus("error");
        },
      );
      return () => {
        cancelled = true;
      };
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [key, nonce]);

    const refetch = useCallback(() => setNonce((n) => n + 1), []);

    useEffect(() => {
      wire.refetchers.add(refetch);
      return () => {
        wire.refetchers.delete(refetch);
      };
    }, [refetch]);

    const last = pages[pages.length - 1];
    const nextCursor = last ? options.getNextPageParam(last) : undefined;

    const fetchNextPage = useCallback(() => {
      const tail = pagesRef.current[pagesRef.current.length - 1];
      const cursor = tail ? options.getNextPageParam(tail) : undefined;
      if (cursor === undefined) return Promise.resolve();
      setFetchingNext(true);
      return options.queryFn({ pageParam: cursor }).then((page) => {
        setPages((prev) => [...prev, page]);
        setFetchingNext(false);
      });
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [key]);

    return {
      data: status === "success" ? { pages } : undefined,
      isPending: status === "pending",
      isError: status === "error",
      error,
      hasNextPage: nextCursor !== undefined,
      isFetchingNextPage: fetchingNext,
      fetchNextPage,
      refetch,
    };
  }

  function useMutation<V>(options: MutationOptions<V>) {
    const [isPending, setPending] = useState(false);
    const [error, setError] = useState<unknown>(null);

    const mutate = (variables: V, callbacks?: { onSuccess?: () => void }) => {
      setPending(true);
      setError(null);
      options.mutationFn(variables).then(
        (data) => {
          setPending(false);
          options.onSuccess?.(data, variables);
          callbacks?.onSuccess?.();
        },
        (failure) => {
          setPending(false);
          setError(failure);
        },
      );
    };

    return { mutate, isPending, error, reset: () => setError(null) };
  }

  function useQueryClient() {
    return {
      // Records the key it was handed AND refetches every mounted list. The
      // key matching a real QueryClient's prefix semantics is queryKeys.ts's
      // job; what this screen's test can check is which keys the mutation
      // declared stale, which is asserted directly.
      invalidateQueries(filters: unknown) {
        wire.invalidated.push(filters);
        for (const refetch of wire.refetchers) refetch();
        return Promise.resolve();
      },
    };
  }

  return { useInfiniteQuery, useMutation, useQueryClient };
});

vi.mock("@/ui/icons", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/ui/icons")>();
  const FakeIcon = (props: Record<string, unknown>) => <svg data-testid="icon" {...props} />;
  return { ...actual, ...Object.fromEntries(Object.keys(actual).map((key) => [key, FakeIcon])) };
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

/**
 * Lets every pending microtask (the token read, the transport promise, the
 * state updates each resolves into) land, with React flushing in between.
 * Several passes because one fetch crosses more than one `await`.
 */
async function settle(passes = 6) {
  for (let i = 0; i < passes; i += 1) {
    await act(async () => {
      await Promise.resolve();
    });
  }
}

function click(element: Element) {
  act(() => {
    fireEvent.click(element);
  });
}

function change(element: Element, value: string) {
  act(() => {
    fireEvent.change(element, { target: { value } });
  });
}

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

function openRoleDialog(fullName: string): HTMLElement {
  click(screen.getByRole("button", { name: `Change role for ${fullName}` }));
  return screen.getByRole("dialog");
}

beforeEach(() => {
  wire.calls.length = 0;
  wire.invalidated.length = 0;
  wire.respond = () => usersPage([AGENT, BUYER]);
});

// ---------------------------------------------------------------------------

describe("UsersScreen", () => {
  it("lists accounts with their role, realtor status, counts and joined date", async () => {
    render(<UsersScreen />);
    await settle();

    const listCall = callAt("GET", 0);
    expect(listCall.url).toBe("http://admin.test/api/admin/users");
    expect(listCall.query?.limit).toBe(50);
    // No filter is active on first paint, and "no filter" has to be an absent
    // query key rather than an empty one.
    expect(listCall.query?.q).toBeUndefined();
    expect(listCall.query?.role).toBeUndefined();
    expect(listCall.query?.realtorStatus).toBeUndefined();
    expect(listCall.query?.cursor).toBeUndefined();

    const agentRow = screen.getByText("Javlon Rustamov").closest("tr") as HTMLElement;
    expect(within(agentRow).getByText("javlon@lacasa.uz")).toBeTruthy();
    expect(within(agentRow).getByText("Agent")).toBeTruthy();
    expect(within(agentRow).getByText("Approved")).toBeTruthy();
    expect(within(agentRow).getByText("24")).toBeTruthy();
    expect(within(agentRow).getByText("12")).toBeTruthy();
    expect(within(agentRow).getByText("14.03.2026")).toBeTruthy();
    expect(within(agentRow).getByText("a3f21e08…")).toBeTruthy();

    const buyerRow = screen.getByText("Dilnoza Yusupova").closest("tr") as HTMLElement;
    expect(within(buyerRow).getByText("Buyer")).toBeTruthy();
    expect(within(buyerRow).getByText("—")).toBeTruthy();
    expect(within(buyerRow).queryByText("None")).toBeNull();

    // Keyset paging with no cursor left: an end marker, never a page number.
    expect(screen.getByText("End of list")).toBeTruthy();
  });

  it("pages with the cursor the server handed back, never a constructed one", async () => {
    wire.respond = (req) =>
      req.query?.cursor === "cursor-1"
        ? usersPage([{ ...AGENT, id: "c0ffee00-0000-4000-8000-000000000001", fullName: "Kamola Rashidova" }])
        : usersPage([AGENT, BUYER], "cursor-1");

    render(<UsersScreen />);
    await settle();

    click(screen.getByRole("button", { name: /Load more/ }));
    await settle();

    expect(callAt("GET", 1).query?.cursor).toBe("cursor-1");
    expect(screen.getByText("Kamola Rashidova")).toBeTruthy();
    // Appended, not replaced.
    expect(screen.getByText("Javlon Rustamov")).toBeTruthy();
  });

  it("shows the database-is-empty message when nothing is filtered away", async () => {
    wire.respond = () => usersPage([]);
    render(<UsersScreen />);
    await settle();

    expect(screen.getByText("No accounts yet")).toBeTruthy();
    expect(screen.getByText(/check the environment strip/)).toBeTruthy();
  });

  it("distinguishes a filtered-away list from an empty one", async () => {
    render(<UsersScreen />);
    await settle();

    wire.respond = () => usersPage([]);
    click(screen.getByRole("button", { name: "Coworker" }));
    await settle();

    expect(screen.getByText("No accounts match these filters")).toBeTruthy();
    expect(screen.queryByText("No accounts yet")).toBeNull();
    expect(callAt("GET", 1).query?.role).toBe("coworker");
  });

  it("filters by realtor status server-side", async () => {
    render(<UsersScreen />);
    await settle();

    change(screen.getByLabelText("Realtor status"), "pending");
    await settle();

    expect(callAt("GET", 1).query?.realtorStatus).toBe("pending");
  });

  it("surfaces a failed list with the API's own message and a retry", async () => {
    wire.respond = () => {
      throw apiError("internal", "Database connection lost", 500);
    };
    render(<UsersScreen />);
    await settle();

    const alert = screen.getByRole("alert");
    expect(within(alert).getByText("Database connection lost")).toBeTruthy();
    expect(within(alert).getByText("internal")).toBeTruthy();

    wire.respond = () => usersPage([AGENT, BUYER]);
    click(screen.getByRole("button", { name: "Try again" }));
    await settle();

    expect(screen.getByText("Javlon Rustamov")).toBeTruthy();
  });

  it("debounces the search box instead of querying per keystroke", async () => {
    vi.useFakeTimers();
    try {
      render(<UsersScreen />);
      await settle();
      expect(getCalls("GET")).toHaveLength(1);

      const box = screen.getByLabelText("Search users");
      change(box, "k");
      change(box, "ka");
      change(box, "kam");
      await settle();

      // Three keystrokes inside the debounce window are still zero requests.
      expect(getCalls("GET")).toHaveLength(1);

      act(() => {
        vi.advanceTimersByTime(300);
      });
      await settle();

      expect(getCalls("GET")).toHaveLength(2);
      expect(callAt("GET", 1).query?.q).toBe("kam");
    } finally {
      vi.useRealTimers();
    }
  });

  describe("changing a role", () => {
    it("never writes without a confirmation", async () => {
      render(<UsersScreen />);
      await settle();

      const dialog = openRoleDialog("Javlon Rustamov");
      expect(getCalls("PATCH")).toHaveLength(0);
      // The record being acted on is restated in full, id and all.
      expect(within(dialog).getByText(AGENT.id)).toBeTruthy();

      click(within(dialog).getByRole("button", { name: "Cancel" }));
      await settle();

      expect(getCalls("PATCH")).toHaveLength(0);
      expect(screen.queryByRole("dialog")).toBeNull();
    });

    it("refuses to submit a change to the role the account already holds", async () => {
      render(<UsersScreen />);
      await settle();

      const dialog = openRoleDialog("Javlon Rustamov");
      click(within(dialog).getByRole("button", { name: "Change to Agent" }));
      await settle();

      expect(getCalls("PATCH")).toHaveLength(0);
      expect(within(dialog).getByText(/already has/)).toBeTruthy();
    });

    it("gives promotion to admin the strongest confirmation on the screen", async () => {
      render(<UsersScreen />);
      await settle();

      const dialog = openRoleDialog("Dilnoza Yusupova");
      change(within(dialog).getByLabelText("New role"), "admin");

      expect(
        within(dialog).getByText("This is the strongest permission the platform has."),
      ).toBeTruthy();
      expect(within(dialog).getByText(/change anyone's role — including yours/)).toBeTruthy();
      // The confirm button names the power being handed over instead of
      // reading "Change role" like every reversible transition does.
      expect(within(dialog).getByRole("button", { name: "Grant admin access" })).toBeTruthy();
    });

    it("explains what a demotion does and does not take with it", async () => {
      render(<UsersScreen />);
      await settle();

      const dialog = openRoleDialog("Javlon Rustamov");
      change(within(dialog).getByLabelText("New role"), "user");

      // Quoted off the row itself, so the reassurance is checkable.
      expect(within(dialog).getByText(/24 ads and 12 leads/)).toBeTruthy();
      expect(within(dialog).getByText(/Nothing is deleted/)).toBeTruthy();
    });

    it("sends the change, closes, and re-reads the list rather than patching it", async () => {
      render(<UsersScreen />);
      await settle();

      wire.respond = (req) => {
        if (req.method === "PATCH") return { user: { ...AGENT, role: "admin" } };
        return usersPage([{ ...AGENT, role: "admin" }, BUYER]);
      };

      const dialog = openRoleDialog("Javlon Rustamov");
      change(within(dialog).getByLabelText("New role"), "admin");
      click(within(dialog).getByRole("button", { name: "Grant admin access" }));
      await settle();

      const patch = callAt("PATCH", 0);
      expect(patch.url).toBe(`http://admin.test/api/admin/users/${AGENT.id}/role`);
      expect(patch.body).toEqual({ role: "admin" });

      expect(screen.queryByRole("dialog")).toBeNull();
      // Both the directory and the overview's per-role counts go stale.
      expect(wire.invalidated).toEqual([{ queryKey: ["users"] }, { queryKey: ["overview"] }]);
      expect(getCalls("GET").length).toBeGreaterThan(1);

      const row = screen.getByText("Javlon Rustamov").closest("tr") as HTMLElement;
      expect(within(row).getByText("Admin")).toBeTruthy();
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
        render(<UsersScreen />);
        await settle();

        wire.respond = (req) => {
          if (req.method === "PATCH") throw apiError(code, "server prose nobody reads", status);
          return usersPage([AGENT, BUYER]);
        };

        const dialog = openRoleDialog(subject);
        change(within(dialog).getByLabelText("New role"), role);
        click(within(dialog).getByRole("button", { name: /^Change to / }));
        await settle();

        // The dialog stays open on a refusal: each of these is something the
        // admin can act on without losing their place.
        expect(screen.queryByRole("dialog")).not.toBeNull();
        expect(within(dialog).getByText(expected)).toBeTruthy();
        // Never the server's raw prose, and never a generic failure line.
        expect(within(dialog).queryByText("server prose nobody reads")).toBeNull();
      },
    );

    it("does not carry one row's refusal into the next row's dialog", async () => {
      render(<UsersScreen />);
      await settle();

      wire.respond = (req) => {
        if (req.method === "PATCH") throw apiError("last_admin", "last admin", 409);
        return usersPage([AGENT, BUYER]);
      };

      const first = openRoleDialog("Javlon Rustamov");
      change(within(first).getByLabelText("New role"), "user");
      click(within(first).getByRole("button", { name: "Change to Buyer" }));
      await settle();
      expect(within(first).getByText(/only admin account left/)).toBeTruthy();

      click(within(first).getByRole("button", { name: "Cancel" }));
      const second = openRoleDialog("Dilnoza Yusupova");
      expect(within(second).queryByText(/only admin account left/)).toBeNull();
    });
  });
});
