/**
 * useAudit.test — the WIRE half of the audit screen's coverage: what
 * `auditQueryOptions()` actually asks the server for.
 *
 * Faked at the Transport seam (the model is
 * @lacasa/api-client/src/testing/fakeTransport.ts, which cannot be imported —
 * that package's tsup config builds only `src/index.ts` and deliberately
 * keeps its test doubles out of the public entry point), so the real
 * `admin.listAudit()` resource runs and the assertions land on the request
 * that would leave the browser. That is the only way to prove the two claims
 * this screen's honesty rests on: that the filters are applied by the SERVER
 * rather than to an already-loaded page, and that the opaque keyset cursor is
 * handed back verbatim.
 *
 * Lives under src/screens/audit/__tests__/ rather than next to the hook
 * because src/data/ is shared ground — this suite owns the audit screen's
 * directory and useAudit.ts itself, not a test slot in src/data/.
 *
 * No React is mounted here at all, which is why `auditQueryOptions` is a
 * plain function rather than something only reachable through a hook.
 */
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { TransportRequest } from "@lacasa/api-client";
import { AUDIT_PAGE_SIZE, auditQueryOptions, auditRowsOf } from "@/data/useAudit";
import { queryKeys } from "@/lib/queryKeys";

const fake = vi.hoisted(() => ({
  calls: [] as unknown[],
  response: { items: [], nextCursor: null } as unknown,
}));

vi.mock("@/lib/apiClient", async () => {
  const { createLaCasaApiClient } = await import("@lacasa/api-client");
  return {
    apiClient: createLaCasaApiClient({
      transport: {
        request<T>(req: TransportRequest): Promise<T> {
          fake.calls.push(req);
          return Promise.resolve(fake.response as T);
        },
      },
      tokenStorage: { getToken: async () => "admin-token", setToken: async () => {} },
      baseUrl: "https://api.test/api",
    }),
  };
});

function lastCall(): TransportRequest {
  const call = (fake.calls as TransportRequest[]).at(-1);
  if (!call) throw new Error("no request reached the transport");
  return call;
}

beforeEach(() => {
  fake.calls.length = 0;
  fake.response = { items: [], nextCursor: null };
});

describe("auditQueryOptions", () => {
  it("asks for one unfiltered page of the log", async () => {
    const options = auditQueryOptions();
    await options.queryFn({ pageParam: options.initialPageParam });

    const call = lastCall();
    expect(call.method).toBe("GET");
    expect(call.url).toBe("https://api.test/api/admin/audit");
    expect(call.query?.limit).toBe(AUDIT_PAGE_SIZE);
    // Absent rather than empty: `?type=` would mean "the empty type".
    expect(call.query?.type).toBeUndefined();
    expect(call.query?.agentId).toBeUndefined();
    expect(call.query?.cursor).toBeUndefined();
  });

  it("sends both filters to the server", async () => {
    const options = auditQueryOptions({
      type: "olx_crosspost_aborted",
      agentId: "9c6e41af-0000-4000-8000-00000000000a",
    });
    await options.queryFn({ pageParam: undefined });

    expect(lastCall().query?.type).toBe("olx_crosspost_aborted");
    expect(lastCall().query?.agentId).toBe("9c6e41af-0000-4000-8000-00000000000a");
  });

  it("passes the opaque cursor back verbatim", async () => {
    const options = auditQueryOptions();
    await options.queryFn({ pageParam: "3f0a11c2-0000-4000-8000-000000000050" });

    expect(lastCall().query?.cursor).toBe("3f0a11c2-0000-4000-8000-000000000050");
  });

  it("keys the cache by filter, and never by cursor", () => {
    expect(auditQueryOptions().queryKey).toEqual(queryKeys.audit.list());
    expect(auditQueryOptions({ type: "ad_sold" }).queryKey).toEqual(
      queryKeys.audit.list({ type: "ad_sold" }),
    );
    // Two different filter sets must not collide…
    expect(auditQueryOptions({ type: "ad_sold" }).queryKey).not.toEqual(
      auditQueryOptions({ type: "ad_created" }).queryKey,
    );
    // …and the key carries nothing that would split one filter's pages apart.
    expect(JSON.stringify(auditQueryOptions().queryKey)).not.toContain("cursor");
  });

  it("stops paging when the server reports the last page", () => {
    const { getNextPageParam } = auditQueryOptions();
    expect(getNextPageParam({ items: [], nextCursor: null })).toBeUndefined();
    expect(getNextPageParam({ items: [], nextCursor: "next-page" })).toBe("next-page");
  });
});

describe("auditRowsOf", () => {
  it("flattens loaded pages into one stream and treats no data as no rows", () => {
    expect(auditRowsOf(undefined)).toEqual([]);
    expect(
      auditRowsOf({
        pages: [
          { items: [{ id: "a" }, { id: "b" }], nextCursor: "b" },
          { items: [{ id: "c" }], nextCursor: null },
        ],
        pageParams: [undefined, "b"],
      } as never).map((row) => row.id),
    ).toEqual(["a", "b", "c"]);
  });
});
