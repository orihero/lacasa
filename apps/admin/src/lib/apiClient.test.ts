/**
 * src/lib/apiClient.test — the three behaviours the transport, not axios, is
 * responsible for. See the file header of ./apiClient for why each one is
 * hand-rolled rather than delegated.
 *
 * `axios.request` is spied on rather than a server being stood up: what is
 * under test is the exact URL that goes out, the exact headers, and the exact
 * shape a failure is reconstructed into — all of which are decided before any
 * socket is opened.
 */
import axios, { AxiosError, AxiosHeaders, type AxiosResponse } from "axios";
import { ApiError } from "@lacasa/domain";
import { axiosTransport, buildUrl, toApiError } from "./apiClient";

function okResponse(data: unknown, status = 200, headers: Record<string, string> = {}) {
  return {
    data,
    status,
    statusText: "OK",
    headers,
    config: { headers: new AxiosHeaders() },
  } as unknown as AxiosResponse;
}

function failure(status: number, statusText: string, data: unknown) {
  const error = new AxiosError(statusText, "ERR_BAD_REQUEST");
  error.response = okResponse(data, status) as AxiosResponse;
  error.response.statusText = statusText;
  return error;
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("buildUrl", () => {
  it("omits undefined and null keys entirely — never `?cursor=` and never `?cursor=null`", () => {
    expect(
      buildUrl("/api/admin/users", { q: "ann", role: undefined, realtorStatus: null }),
    ).toBe("/api/admin/users?q=ann");
  });

  it("leaves the url untouched when nothing survives, so it shares a cache entry with no query at all", () => {
    expect(buildUrl("/api/admin/users", { role: undefined, realtorStatus: null })).toBe(
      "/api/admin/users",
    );
    expect(buildUrl("/api/admin/users")).toBe("/api/admin/users");
  });

  it("keeps falsy-but-present values, which mean something", () => {
    expect(buildUrl("/x", { limit: 0, archived: false, q: "" })).toBe(
      "/x?limit=0&archived=false&q=",
    );
  });
});

describe("toApiError", () => {
  it("reconstructs the API's own { error: { code, message } } body", () => {
    const error = toApiError(409, "Conflict", {
      error: { code: "validation", message: "not_pending" },
    });
    expect(error).toBeInstanceOf(ApiError);
    expect(error.code).toBe("validation");
    expect(error.message).toBe("not_pending");
    expect(error.status).toBe(409);
  });

  it("never fabricates a code for a body that is not ours", () => {
    // A proxy's HTML 502, which axios hands back as a raw string.
    const error = toApiError(502, "Bad Gateway", "<html>nope</html>");
    expect(error.code).toBe("internal");
    expect(error.message).toBe("Bad Gateway");
    expect(error.status).toBe(502);
  });

  it("falls back to the status line when there is not even a statusText", () => {
    expect(toApiError(500, "", undefined).message).toBe("Request failed with status 500");
  });
});

describe("axiosTransport", () => {
  it("sends the built url and no `params`, so axios cannot re-encode the query", async () => {
    const request = vi.spyOn(axios, "request").mockResolvedValue(okResponse({ items: [] }));

    await axiosTransport.request({
      method: "GET",
      url: "http://localhost:4200/api/admin/audit",
      query: { type: "ad_created", agentId: undefined, cursor: null },
    });

    const config = request.mock.calls[0]?.[0];
    expect(config?.url).toBe("http://localhost:4200/api/admin/audit?type=ad_created");
    expect(config?.params).toBeUndefined();
  });

  it("only advertises a JSON body when there is one", async () => {
    const request = vi.spyOn(axios, "request").mockResolvedValue(okResponse({}));

    await axiosTransport.request({ method: "GET", url: "/x", headers: { Authorization: "Bearer t" } });
    expect(request.mock.calls[0]?.[0]?.headers).toEqual({ Authorization: "Bearer t" });

    await axiosTransport.request({ method: "POST", url: "/x", body: { role: "agent" } });
    expect(request.mock.calls[1]?.[0]?.headers).toEqual({ "Content-Type": "application/json" });
  });

  it("resolves an empty response to undefined rather than to axios's empty string", async () => {
    vi.spyOn(axios, "request").mockResolvedValue(okResponse("", 204));
    await expect(axiosTransport.request({ method: "DELETE", url: "/x" })).resolves.toBeUndefined();

    vi.spyOn(axios, "request").mockResolvedValue(okResponse("", 200, { "content-length": "0" }));
    await expect(axiosTransport.request({ method: "GET", url: "/x" })).resolves.toBeUndefined();
  });

  it("turns a non-2xx into an ApiError, because every caller only catches ApiError", async () => {
    vi.spyOn(axios, "request").mockRejectedValue(
      failure(401, "Unauthorized", { error: { code: "unauthorized", message: "Token expired" } }),
    );

    await expect(axiosTransport.request({ method: "GET", url: "/x" })).rejects.toMatchObject({
      name: "ApiError",
      code: "unauthorized",
      status: 401,
    });
  });

  it("rethrows a response-less failure unchanged, so a network blip cannot look like a 401", async () => {
    // This is what keeps lib/auth's "only a 401 clears the token" rule honest.
    const offline = new AxiosError("Network Error", "ERR_NETWORK");
    vi.spyOn(axios, "request").mockRejectedValue(offline);

    await expect(axiosTransport.request({ method: "GET", url: "/x" })).rejects.toBe(offline);
    expect(ApiError.isApiError(offline)).toBe(false);
  });
});
