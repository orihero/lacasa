/**
 * useUsers / useSetUserRole — the directory's data layer, tested apart from
 * the screen that renders it.
 *
 * What lives here rather than in UsersScreen.test.tsx: the things that are
 * true of the HOOK no matter which screen calls it — the page size, the
 * `undefined`-not-empty-string normalisation, the trimming that keeps the
 * cache key and the request agreeing, the opaque cursor being handed back
 * untouched, and the two invalidations (in order, and only those two) that a
 * role change fires. The screen suite then pins the same contract end to end
 * over a real transport; this one pins it where the reasons are readable.
 */
import type { ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, renderHook, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AdminPage, AdminUserRow } from "@lacasa/api-client";
import { apiClient } from "@/lib/apiClient";
import { queryKeys } from "@/lib/queryKeys";
import { USERS_PAGE_SIZE, useSetUserRole, useUsers } from "@/data/useUsers";

vi.mock("@/lib/apiClient", () => ({
  API_BASE_URL: "http://admin.test/api",
  apiClient: { admin: { listUsers: vi.fn(), setUserRole: vi.fn() } },
  localStorageTokenStorage: { getToken: vi.fn(), setToken: vi.fn() },
}));

const ROW: AdminUserRow = {
  id: "a3f21e08-1c44-4b0e-9f21-3d6b0e5a71c2",
  fullName: "Javlon Rustamov",
  email: "javlon@lacasa.uz",
  phoneNumber: "+998901112233",
  role: "agent",
  avatar: null,
  agentId: null,
  realtor: null,
  createdAt: "2026-03-14T09:00:00.000Z",
  counts: { ads: 24, leads: 12 },
};

function page(nextCursor: string | null = null): AdminPage<AdminUserRow> {
  return { items: [ROW], nextCursor };
}

function createClient(): QueryClient {
  return new QueryClient({
    defaultOptions: { queries: { retry: false, staleTime: 0 }, mutations: { retry: false } },
  });
}

function wrapperFor(queryClient: QueryClient) {
  return function Wrapper({ children }: { children: ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

const listUsers = vi.mocked(apiClient.admin.listUsers);
const setUserRole = vi.mocked(apiClient.admin.setUserRole);

beforeEach(() => {
  vi.clearAllMocks();
  listUsers.mockResolvedValue(page());
  setUserRole.mockResolvedValue({ user: { ...ROW, role: "admin" } });
});

describe("useUsers", () => {
  it("asks for 50 rows and sends no filter keys at all when nothing is filtered", async () => {
    const queryClient = createClient();
    const { result } = renderHook(() => useUsers(), { wrapper: wrapperFor(queryClient) });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    // `undefined`, not `""`: sending `?q=` would ask the server to match
    // everything against the empty string. 50 rather than the server's
    // default of 25 because the directory is a scanning surface.
    expect(listUsers).toHaveBeenCalledTimes(1);
    expect(listUsers).toHaveBeenCalledWith({
      q: undefined,
      role: undefined,
      realtorStatus: undefined,
      limit: 50,
      cursor: undefined,
    });
    expect(USERS_PAGE_SIZE).toBe(50);
  });

  it("passes the filters through and folds an all-whitespace search to no search", async () => {
    const queryClient = createClient();
    const { result } = renderHook(
      () => useUsers({ q: "   ", role: "coworker", realtorStatus: "pending" }),
      { wrapper: wrapperFor(queryClient) },
    );

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(listUsers).toHaveBeenCalledWith({
      q: undefined,
      role: "coworker",
      realtorStatus: "pending",
      limit: 50,
      cursor: undefined,
    });
  });

  it("trims the search term in the request and in the cache key alike", async () => {
    const queryClient = createClient();
    const { result } = renderHook(() => useUsers({ q: "  kam  " }), {
      wrapper: wrapperFor(queryClient),
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    // A trailing space must not hit the same cache entry while asking the
    // database a different question, so both halves are trimmed.
    expect(listUsers.mock.calls[0]?.[0]?.q).toBe("kam");
    expect(queryClient.getQueryData(queryKeys.users.list({ q: "kam" }))).toBeTruthy();
  });

  it("keeps cursor and limit out of the cache key", async () => {
    const queryClient = createClient();
    listUsers.mockResolvedValue(page("cursor-1"));
    const { result } = renderHook(() => useUsers(), { wrapper: wrapperFor(queryClient) });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    // Folding the cursor in would give every page its own cache entry and
    // defeat the pagination entirely.
    const keys = queryClient.getQueryCache().getAll().map((query) => query.queryKey);
    expect(keys).toEqual([["users", "list", { q: null, role: null, realtorStatus: null }]]);
  });

  it("hands the server's opaque cursor straight back on the next page", async () => {
    const queryClient = createClient();
    listUsers.mockResolvedValueOnce(page("cursor-1")).mockResolvedValueOnce(page(null));

    const { result } = renderHook(() => useUsers(), { wrapper: wrapperFor(queryClient) });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.hasNextPage).toBe(true);

    await act(async () => {
      await result.current.fetchNextPage();
    });
    await waitFor(() => expect(listUsers).toHaveBeenCalledTimes(2));

    expect(listUsers.mock.calls[1]?.[0]?.cursor).toBe("cursor-1");
    // Pages append, and a null nextCursor is the end of the list.
    await waitFor(() => expect(result.current.data?.pages).toHaveLength(2));
    await waitFor(() => expect(result.current.hasNextPage).toBe(false));
  });

  it("treats a null nextCursor as the end rather than as a cursor", async () => {
    const queryClient = createClient();
    const { result } = renderHook(() => useUsers(), { wrapper: wrapperFor(queryClient) });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(result.current.hasNextPage).toBe(false);
    await act(async () => {
      await result.current.fetchNextPage();
    });
    expect(listUsers).toHaveBeenCalledTimes(1);
  });
});

describe("useSetUserRole", () => {
  it("PATCHes the one account and re-reads rather than patching the cache", async () => {
    const queryClient = createClient();
    const invalidate = vi.spyOn(queryClient, "invalidateQueries");

    const { result } = renderHook(() => useSetUserRole(), { wrapper: wrapperFor(queryClient) });
    act(() => {
      result.current.mutate({ id: ROW.id, role: "admin" });
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(setUserRole).toHaveBeenCalledWith(ROW.id, "admin");
    // Both are load-bearing and neither is redundant: `["users"]` is the
    // prefix of the list AND of users.detail(id); `["overview"]` because the
    // overview counts accounts by role and this just moved one. The
    // applications list is deliberately NOT invalidated — a role change never
    // touches realtorStatus.
    expect(invalidate.mock.calls.map((call) => call[0])).toEqual([
      { queryKey: ["users"] },
      { queryKey: ["overview"] },
    ]);
    // No hand-written cache row: the server's guard rails count inputs this
    // client cannot see, so a refetch is the only trustworthy post-state.
    expect(queryClient.getQueryData(queryKeys.users.detail(ROW.id))).toBeUndefined();
  });

  it("does not invalidate anything when the server refuses", async () => {
    const queryClient = createClient();
    const invalidate = vi.spyOn(queryClient, "invalidateQueries");
    setUserRole.mockRejectedValue(new Error("last admin"));

    const { result } = renderHook(() => useSetUserRole(), { wrapper: wrapperFor(queryClient) });
    act(() => {
      result.current.mutate({ id: ROW.id, role: "user" });
    });

    await waitFor(() => expect(result.current.isError).toBe(true));

    expect(invalidate).not.toHaveBeenCalled();
  });
});
