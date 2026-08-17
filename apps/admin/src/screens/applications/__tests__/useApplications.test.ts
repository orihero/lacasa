/**
 * useApplications.test — the applications screen's data layer, driven against
 * a REAL @lacasa/api-client wired to a faked Transport (the same double
 * packages/api-client/src/testing/fakeTransport.ts provides for that package's
 * own suite; it is not reachable from here because the package only publishes
 * `dist`, so an equivalent recorder is built inline below).
 *
 * Going through the real `admin` resource rather than stubbing
 * `apiClient.admin.listApplications` is the whole point: what this file is
 * checking is the CONTRACT — that the queue asks for `/admin/applications`
 * with the status and page size it thinks it is asking for, that the cursor is
 * threaded through as `pageParam` and omitted entirely on the first page, and
 * that a decision hits the approve/reject endpoint for the right user. A
 * stubbed resource would assert only that this file calls itself.
 *
 * NOTHING HERE MOUNTS REACT, and that is not a stylistic choice: apps/web pins
 * React 18 and claims the hoisted copy at the repo root, so the hoisted
 * @tanstack/react-query resolves its own `react` to that copy while this app's
 * components resolve to the nested React 19 — rendering a hook through
 * `useInfiniteQuery` here dies with "Cannot read properties of null (reading
 * 'useEffect')" before any assertion runs (verified; src/test/render.tsx
 * documents the same split for react-dom). useApplications.ts is therefore
 * split into plain options factories plus two one-line hooks, and this file
 * exercises the factories.
 *
 * It lives under screens/applications/__tests__ rather than next to the module
 * it tests because src/data/ belongs to the whole app and this screen's agent
 * owns only its own directory.
 */
import { describe, expect, it, vi, beforeEach } from "vitest";
import type { Transport, TransportRequest } from "@lacasa/api-client";
import { ApiError } from "@lacasa/domain";
import { queryKeys } from "@/data/queryKeys";
import {
  APPLICATIONS_PAGE_SIZE,
  applicationsQueryOptions,
  decideApplicationMutationOptions,
  flattenApplicationPages,
  isApplicationAlreadyDecided,
} from "@/data/useApplications";
import { makeApplication, makePage } from "./fixtures";

// vi.hoisted, because the vi.mock factory below is lifted above the imports
// and cannot close over an ordinary module-scope const — the base URL included,
// which is why it lives in here rather than next to the other constants.
const server = vi.hoisted(() => {
  const baseUrl = "http://admin.test/api";
  const calls: TransportRequest[] = [];
  let response: unknown;
  let failure: unknown;

  const transport: Transport = {
    request<T>(req: TransportRequest): Promise<T> {
      calls.push(req);
      return failure ? Promise.reject(failure) : Promise.resolve(response as T);
    },
  };

  return {
    baseUrl,
    calls,
    transport,
    reset() {
      calls.length = 0;
      response = undefined;
      failure = undefined;
    },
    replyWith(value: unknown) {
      response = value;
      failure = undefined;
    },
  };
});

vi.mock("@/lib/apiClient", async () => {
  const { createLaCasaApiClient } = await import("@lacasa/api-client");
  return {
    apiClient: createLaCasaApiClient({
      transport: server.transport,
      tokenStorage: {
        getToken: () => Promise.resolve("admin-token"),
        setToken: () => Promise.resolve(),
      },
      baseUrl: server.baseUrl,
    }),
  };
});

beforeEach(() => {
  server.reset();
});

/** The one call the fake transport recorded. Fails loudly if there wasn't exactly one. */
function onlyCall(): TransportRequest {
  expect(server.calls).toHaveLength(1);
  return server.calls[0]!;
}

describe("applicationsQueryOptions", () => {
  it("keys off the shared factory so an invalidation can find it", () => {
    expect(applicationsQueryOptions("approved").queryKey).toEqual(
      queryKeys.applications.list({ status: "approved" }),
    );
  });

  it("asks for the filtered first page with no cursor at all", async () => {
    server.replyWith(makePage([makeApplication()], null));
    const options = applicationsQueryOptions("pending");

    await options.queryFn({ pageParam: options.initialPageParam });

    const call = onlyCall();
    expect(call.method).toBe("GET");
    expect(call.url).toBe(`${server.baseUrl}/admin/applications`);
    expect(call.query).toEqual({
      status: "pending",
      limit: APPLICATIONS_PAGE_SIZE,
      // Undefined, never "" — an empty cursor would mean "the empty cursor"
      // to the server rather than "start at the beginning".
      cursor: undefined,
    });
  });

  it("threads the server's opaque cursor back on the next page", async () => {
    server.replyWith(makePage([], null));

    await applicationsQueryOptions("rejected").queryFn({ pageParam: "cursor-from-page-1" });

    expect(onlyCall().query).toMatchObject({
      status: "rejected",
      cursor: "cursor-from-page-1",
    });
  });

  it("stops paging exactly when the server says the page was the last", () => {
    const { getNextPageParam } = applicationsQueryOptions("pending");
    expect(getNextPageParam(makePage([makeApplication()], "next-1"))).toBe("next-1");
    // A full-length final page must still end the list: "is there more?" comes
    // from nextCursor, never from the row count.
    expect(getNextPageParam(makePage([makeApplication()], null))).toBeNull();
  });
});

describe("flattenApplicationPages", () => {
  it("is an empty list before the first page arrives", () => {
    expect(flattenApplicationPages(undefined)).toEqual([]);
  });

  it("concatenates the pages in server order", () => {
    const rows = flattenApplicationPages({
      pages: [
        makePage([makeApplication({ id: "u1" }), makeApplication({ id: "u2" })], "c1"),
        makePage([makeApplication({ id: "u3" })], null),
      ],
      pageParams: [null, "c1"],
    });
    expect(rows.map((row) => row.id)).toEqual(["u1", "u2", "u3"]);
  });
});

describe("isApplicationAlreadyDecided", () => {
  it("recognises the 409 another admin caused", () => {
    // "not_pending" is not in @lacasa/domain's ERROR_CODES — the cast mirrors
    // what lib/apiClient.ts's toApiError does with the real response body.
    const error = new ApiError("internal" as never, "Already decided", 409);
    Object.defineProperty(error, "code", { value: "not_pending" });
    expect(isApplicationAlreadyDecided(error)).toBe(true);
  });

  it("does not mistake other conflicts, other statuses or plain errors for it", () => {
    const otherConflict = new ApiError("internal" as never, "Last admin", 409);
    Object.defineProperty(otherConflict, "code", { value: "last_admin" });

    const wrongStatus = new ApiError("internal" as never, "Already decided", 400);
    Object.defineProperty(wrongStatus, "code", { value: "not_pending" });

    expect(isApplicationAlreadyDecided(otherConflict)).toBe(false);
    expect(isApplicationAlreadyDecided(wrongStatus)).toBe(false);
    expect(isApplicationAlreadyDecided(new Error("network down"))).toBe(false);
    expect(isApplicationAlreadyDecided(undefined)).toBe(false);
  });
});

describe("decideApplicationMutationOptions", () => {
  function stubClient() {
    return { invalidateQueries: vi.fn() };
  }

  function invalidatedKeys(client: ReturnType<typeof stubClient>) {
    return client.invalidateQueries.mock.calls.map(([arg]) => arg.queryKey);
  }

  it("approves through the approve endpoint", async () => {
    server.replyWith({ user: { id: "u1" } });
    await decideApplicationMutationOptions(stubClient()).mutationFn!(
      { userId: "u1", decision: "approve" },
      // react-query hands the mutationFn a MutationFunctionContext it does not
      // read; nothing in this codebase should have to construct one to test
      // the request it makes.
      undefined as never,
    );

    const call = onlyCall();
    expect(call.method).toBe("POST");
    expect(call.url).toBe(`${server.baseUrl}/admin/applications/u1/approve`);
  });

  it("rejects through the reject endpoint", async () => {
    server.replyWith({ user: { id: "u2" } });
    await decideApplicationMutationOptions(stubClient()).mutationFn!(
      { userId: "u2", decision: "reject" },
      undefined as never,
    );

    expect(onlyCall().url).toBe(`${server.baseUrl}/admin/applications/u2/reject`);
  });

  it("invalidates the queue, the overview counts and the users directory on success", () => {
    const client = stubClient();
    const options = decideApplicationMutationOptions(client);

    options.onSuccess!({ user: { id: "u1" } } as never, { userId: "u1", decision: "approve" }, undefined, undefined as never);

    expect(invalidatedKeys(client)).toEqual([
      queryKeys.applications.all,
      queryKeys.overview.all,
      queryKeys.users.all,
    ]);
  });

  it("refetches the queue when another admin got there first", () => {
    const client = stubClient();
    const conflict = new ApiError("internal" as never, "Already decided", 409);
    Object.defineProperty(conflict, "code", { value: "not_pending" });

    decideApplicationMutationOptions(client).onError!(
      conflict,
      { userId: "u1", decision: "approve" },
      undefined,
      undefined as never,
    );

    // Not users.all: nobody was promoted, so that directory is still accurate.
    expect(invalidatedKeys(client)).toEqual([queryKeys.applications.all, queryKeys.overview.all]);
  });

  it("leaves the cache alone when the decision simply failed", () => {
    const client = stubClient();

    decideApplicationMutationOptions(client).onError!(
      new ApiError("internal", "Boom", 500),
      { userId: "u1", decision: "reject" },
      undefined,
      undefined as never,
    );

    expect(client.invalidateQueries).not.toHaveBeenCalled();
  });
});
