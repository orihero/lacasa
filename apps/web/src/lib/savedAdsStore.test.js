import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./apiClient";
import { getAuthToken } from "./api";
import { useSavedAdsStore } from "./savedAdsStore";

vi.mock("./apiClient", () => ({
  apiClient: {
    savedAds: {
      list: vi.fn(),
      save: vi.fn(),
      unsave: vi.fn(),
    },
  },
}));

vi.mock("./api", () => ({
  getAuthToken: vi.fn(),
}));

describe("useSavedAdsStore", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useSavedAdsStore.setState({
      savedIds: new Set(),
      savedList: [],
      isLoading: false,
      loaded: false,
    });
  });

  it("fetchSaved skips the network entirely without a token", async () => {
    getAuthToken.mockReturnValue(null);

    await useSavedAdsStore.getState().fetchSaved();

    expect(apiClient.savedAds.list).not.toHaveBeenCalled();
    expect(useSavedAdsStore.getState().loaded).toBe(true);
  });

  it("fetchSaved populates the id set from the list", async () => {
    getAuthToken.mockReturnValue("token");
    apiClient.savedAds.list.mockResolvedValueOnce([{ id: "ad-1" }, { id: "ad-2" }]);

    await useSavedAdsStore.getState().fetchSaved();

    expect(useSavedAdsStore.getState().savedIds).toEqual(new Set(["ad-1", "ad-2"]));
    expect(useSavedAdsStore.getState().savedList).toHaveLength(2);
  });

  it("fetchSaved degrades to empty on failure (forbidden for non-buyers)", async () => {
    getAuthToken.mockReturnValue("token");
    apiClient.savedAds.list.mockRejectedValueOnce(new Error("forbidden"));

    await useSavedAdsStore.getState().fetchSaved();

    expect(useSavedAdsStore.getState().savedIds).toEqual(new Set());
    expect(useSavedAdsStore.getState().loaded).toBe(true);
  });

  it("toggleSaved applies optimistically and calls save for a new id", async () => {
    apiClient.savedAds.save.mockResolvedValueOnce({ ok: true });

    const promise = useSavedAdsStore.getState().toggleSaved("ad-1");
    expect(useSavedAdsStore.getState().savedIds.has("ad-1")).toBe(true);

    await promise;
    expect(apiClient.savedAds.save).toHaveBeenCalledWith("ad-1");
  });

  it("toggleSaved unsaves a saved id and drops it from the list", async () => {
    useSavedAdsStore.setState({
      savedIds: new Set(["ad-1"]),
      savedList: [{ id: "ad-1" }],
    });
    apiClient.savedAds.unsave.mockResolvedValueOnce(undefined);

    await useSavedAdsStore.getState().toggleSaved("ad-1");

    expect(apiClient.savedAds.unsave).toHaveBeenCalledWith("ad-1");
    expect(useSavedAdsStore.getState().savedIds.has("ad-1")).toBe(false);
    expect(useSavedAdsStore.getState().savedList).toEqual([]);
  });

  it("toggleSaved rolls back when the write fails", async () => {
    apiClient.savedAds.save.mockRejectedValueOnce(new Error("boom"));

    await useSavedAdsStore.getState().toggleSaved("ad-1");

    expect(useSavedAdsStore.getState().savedIds.has("ad-1")).toBe(false);
  });
});
