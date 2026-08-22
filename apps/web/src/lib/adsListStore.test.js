import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./apiClient";
import { useListStore } from "./adsListStore";

vi.mock("./apiClient", () => ({
  apiClient: {
    ads: {
      list: vi.fn(),
      getAds: vi.fn(),
      getById: vi.fn(),
      getStageCounts: vi.fn(),
    },
  },
}));

describe("useListStore (adsListStore)", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useListStore.setState({
      list: [],
      myList: [],
      adsData: {},
      stageCount: { stage1: 0, stage2: 0 },
      isLoading: true,
    });
  });

  it("fetchAdsList populates list from the public apiClient.ads.list()", async () => {
    apiClient.ads.list.mockResolvedValueOnce([{ id: "ad-1" }]);

    await useListStore.getState().fetchAdsList();

    expect(useListStore.getState().list).toEqual([{ id: "ad-1" }]);
  });

  it("fetchAdsByAgentId defaults to the 'public' scope when the caller doesn't say otherwise", async () => {
    apiClient.ads.getAds.mockResolvedValueOnce([{ id: "ad-1" }]);

    await useListStore.getState().fetchAdsByAgentId("agent-1");

    expect(apiClient.ads.getAds).toHaveBeenCalledWith({
      scope: "public",
      agentId: "agent-1",
      filters: {},
      sort: "newest",
    });
    expect(useListStore.getState().myList).toEqual([{ id: "ad-1" }]);
  });

  it("fetchAdsByAgentId passes the caller's explicit 'mine' scope through instead of inferring it", async () => {
    apiClient.ads.getAds.mockResolvedValueOnce([{ id: "ad-1", stage: "DRAFT" }]);

    await useListStore.getState().fetchAdsByAgentId("agent-1", { city: "Tashkent" }, "highestPrice", "mine");

    expect(apiClient.ads.getAds).toHaveBeenCalledWith({
      scope: "mine",
      agentId: "agent-1",
      filters: { city: "Tashkent" },
      sort: "highestPrice",
    });
  });

  it("fetchAdsByAgentId falls back to an empty myList on failure", async () => {
    apiClient.ads.getAds.mockRejectedValueOnce(new Error("boom"));

    await useListStore.getState().fetchAdsByAgentId("agent-1", {}, "newest", "mine");

    expect(useListStore.getState().myList).toEqual([]);
  });

  it("fetchAdsById populates adsData from apiClient.ads.getById()", async () => {
    apiClient.ads.getById.mockResolvedValueOnce({ id: "ad-1" });

    await useListStore.getState().fetchAdsById("ad-1");

    expect(apiClient.ads.getById).toHaveBeenCalledWith("ad-1");
    expect(useListStore.getState().adsData).toEqual({ id: "ad-1" });
  });

  it("fetchAdsByStage populates stageCount from apiClient.ads.getStageCounts()", async () => {
    apiClient.ads.getStageCounts.mockResolvedValueOnce({ stage1: 3, stage2: 5, stage3: 1 });

    await useListStore.getState().fetchAdsByStage();

    expect(useListStore.getState().stageCount).toEqual({ stage1: 3, stage2: 5 });
  });
});
