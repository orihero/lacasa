/**
 * useOverview.test — the data hook, tested apart from the screen because the
 * thing worth pinning here is not a rendering: it is WHICH CACHE ENTRY the one
 * request writes to.
 *
 * The rail's Applications and Users badges never fetch. They subscribe to
 * `queryKeys.overview.summary()` with `enabled: false` and read
 * `applications.pending` / `users.total` out of whatever this hook put there.
 * Nothing imports anything from the other side of that contract, so a key that
 * drifted by one segment would leave the badges permanently empty and no other
 * test in the app would notice — hence the assertion against the query client's
 * cache rather than against the hook's return value alone.
 */
import type { ReactNode } from "react";
import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AdminOverview } from "@lacasa/api-client";
import { ApiError } from "@lacasa/domain";
import { apiClient } from "@/lib/apiClient";
import { queryKeys } from "@/lib/queryKeys";
import { useOverview } from "@/data/useOverview";

vi.mock("@/lib/apiClient", () => ({
  API_BASE_URL: "http://localhost:4200/api",
  apiClient: { admin: { overview: vi.fn() } },
}));

const OVERVIEW: AdminOverview = {
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
  recentSignups: [],
};

function renderOverviewHook() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false, staleTime: 0 } },
  });
  function Wrapper({ children }: { children: ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  }
  return { ...renderHook(() => useOverview(), { wrapper: Wrapper }), queryClient };
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe("useOverview", () => {
  it("reads the overview with no parameters at all", async () => {
    vi.mocked(apiClient.admin.overview).mockResolvedValue(OVERVIEW);
    const { result } = renderOverviewHook();

    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data).toEqual(OVERVIEW);
    // The endpoint takes nothing: no paging, no cursor, no filters, no search.
    expect(apiClient.admin.overview).toHaveBeenCalledTimes(1);
    expect(vi.mocked(apiClient.admin.overview).mock.calls[0]).toEqual([]);
  });

  it("fills the exact cache entry the rail's badges subscribe to", async () => {
    vi.mocked(apiClient.admin.overview).mockResolvedValue(OVERVIEW);
    const { result, queryClient } = renderOverviewHook();

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(queryClient.getQueryData(queryKeys.overview.summary())).toEqual(OVERVIEW);
    // Spelled out once, here, so a change to the key factory that broke the
    // rail would fail loudly rather than silently emptying two badges.
    expect(queryKeys.overview.summary()).toEqual(["overview", "summary"]);
  });

  it("hands the caller the API's own error rather than swallowing it", async () => {
    vi.mocked(apiClient.admin.overview).mockRejectedValue(
      new ApiError("forbidden", "Not allowed for this role", 403),
    );
    const { result } = renderOverviewHook();

    await waitFor(() => expect(result.current.isError).toBe(true));
    expect(result.current.error?.code).toBe("forbidden");
    expect(result.current.error?.message).toBe("Not allowed for this role");
  });
});
