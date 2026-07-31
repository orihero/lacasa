import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./apiClient";
import { getAuthToken, setAuthToken } from "./api";
import { TGService } from "../services/tg";
import { useUserStore } from "./userStore";

vi.mock("./apiClient", () => ({
  apiClient: {
    auth: { me: vi.fn() },
    publish: { getInstagramAccounts: vi.fn() },
    agents: { getById: vi.fn() },
  },
}));

vi.mock("./api", () => ({
  getAuthToken: vi.fn(),
  setAuthToken: vi.fn(),
}));

vi.mock("../services/tg", () => ({
  TGService: { init: vi.fn() },
}));

describe("useUserStore", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useUserStore.setState({ currentUser: null, isLoading: true, agent: {} });
  });

  it("fetchUserInfo skips the session read entirely when there is no stored token", async () => {
    getAuthToken.mockReturnValue(null);

    await useUserStore.getState().fetchUserInfo();

    expect(apiClient.auth.me).not.toHaveBeenCalled();
    expect(useUserStore.getState().currentUser).toBeNull();
    expect(useUserStore.getState().isLoading).toBe(false);
  });

  it("fetchUserInfo (loadSession) sets currentUser from apiClient.auth.me() with empty tg/ig accounts when the user has neither", async () => {
    getAuthToken.mockReturnValue("tok");
    apiClient.auth.me.mockResolvedValueOnce({ user: { id: "u1", role: "agent" } });

    await useUserStore.getState().fetchUserInfo();

    expect(apiClient.auth.me).toHaveBeenCalled();
    expect(apiClient.publish.getInstagramAccounts).not.toHaveBeenCalled();
    expect(TGService.init).not.toHaveBeenCalled();
    expect(useUserStore.getState().currentUser).toEqual({
      id: "u1",
      role: "agent",
      tgAccounts: [],
      igAccounts: undefined,
    });
  });

  it("fetchUserInfo (enrichInstagramAccounts) backfills igAccounts via apiClient.publish.getInstagramAccounts()", async () => {
    getAuthToken.mockReturnValue("tok");
    apiClient.auth.me.mockResolvedValueOnce({
      user: { id: "u1", role: "agent", igAccounts: [{ igUserId: "ig1", username: null, expiresAt: null }] },
    });
    apiClient.publish.getInstagramAccounts.mockResolvedValueOnce({
      accounts: [{ igUserId: "ig1", username: "lacasa", expiresAt: null, followers_count: 42 }],
    });

    await useUserStore.getState().fetchUserInfo();

    expect(useUserStore.getState().currentUser.igAccounts).toEqual([
      { igUserId: "ig1", username: "lacasa", expiresAt: null, followers_count: 42 },
    ]);
  });

  it("fetchUserInfo (enrichInstagramAccounts) keeps the un-enriched igAccounts if the enrichment call fails", async () => {
    getAuthToken.mockReturnValue("tok");
    const stubAccounts = [{ igUserId: "ig1", username: null, expiresAt: null }];
    apiClient.auth.me.mockResolvedValueOnce({ user: { id: "u1", role: "agent", igAccounts: stubAccounts } });
    apiClient.publish.getInstagramAccounts.mockRejectedValueOnce(new Error("boom"));

    await useUserStore.getState().fetchUserInfo();

    expect(useUserStore.getState().currentUser.igAccounts).toEqual(stubAccounts);
  });

  it("fetchUserInfo (enrichTelegramAccounts) resolves tgAccounts via TGService.init() when the user has tgChatIds", async () => {
    getAuthToken.mockReturnValue("tok");
    apiClient.auth.me.mockResolvedValueOnce({ user: { id: "u1", role: "agent", tgChatIds: [111] } });
    TGService.init.mockResolvedValueOnce([{ id: 111, title: "La Casa" }]);

    await useUserStore.getState().fetchUserInfo();

    expect(TGService.init).toHaveBeenCalledWith([111]);
    expect(useUserStore.getState().currentUser.tgAccounts).toEqual([{ id: 111, title: "La Casa" }]);
  });

  it("fetchUserInfo clears the stored token and currentUser when the session read fails", async () => {
    getAuthToken.mockReturnValue("tok");
    apiClient.auth.me.mockRejectedValueOnce(new Error("401"));

    await useUserStore.getState().fetchUserInfo();

    expect(setAuthToken).toHaveBeenCalledWith(null);
    expect(useUserStore.getState().currentUser).toBeNull();
  });

  it("logout clears the token and currentUser", () => {
    useUserStore.setState({ currentUser: { id: "u1" }, isLoading: false });

    useUserStore.getState().logout();

    expect(setAuthToken).toHaveBeenCalledWith(null);
    expect(useUserStore.getState().currentUser).toBeNull();
  });

  it("fetchUserById populates agent from apiClient.agents.getById()", async () => {
    apiClient.agents.getById.mockResolvedValueOnce({ id: "agent-1", fullName: "Agent Smith" });

    await useUserStore.getState().fetchUserById("agent-1");

    expect(apiClient.agents.getById).toHaveBeenCalledWith("agent-1");
    expect(useUserStore.getState().agent).toEqual({ id: "agent-1", fullName: "Agent Smith" });
  });

  it("fetchUserById sets agent to null on failure", async () => {
    apiClient.agents.getById.mockRejectedValueOnce(new Error("boom"));

    await useUserStore.getState().fetchUserById("agent-1");

    expect(useUserStore.getState().agent).toBeNull();
  });
});
