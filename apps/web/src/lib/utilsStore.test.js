import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./apiClient";
import { useUtilsStore } from "./utilsStore";

vi.mock("./apiClient", () => ({
  apiClient: {
    utils: {
      getCurrency: vi.fn(),
      getNearbyPlaces: vi.fn(),
    },
  },
}));

describe("useUtilsStore", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useUtilsStore.setState({ currency: [], nearbyPlaceData: [], isLoading: true });
  });

  it("fetchCurrency wraps apiClient.utils.getCurrency() into the { id, currency } shape components read", async () => {
    apiClient.utils.getCurrency.mockResolvedValueOnce({ code: "USD", rate: 12750 });

    await useUtilsStore.getState().fetchCurrency();

    expect(useUtilsStore.getState().currency).toEqual([{ id: "USD", currency: 12750 }]);
    expect(useUtilsStore.getState().isLoading).toBe(false);
  });

  it("fetchCurrency falls back to an empty array on failure", async () => {
    apiClient.utils.getCurrency.mockRejectedValueOnce(new Error("boom"));

    await useUtilsStore.getState().fetchCurrency();

    expect(useUtilsStore.getState().currency).toEqual([]);
  });

  it("fetchNearbyPlace wraps apiClient.utils.getNearbyPlaces() into the { id, data } shape components read", async () => {
    apiClient.utils.getNearbyPlaces.mockResolvedValueOnce(["Metro", "School"]);

    await useUtilsStore.getState().fetchNearbyPlace();

    expect(useUtilsStore.getState().nearbyPlaceData).toEqual([{ id: "nearby", data: ["Metro", "School"] }]);
  });

  it("fetchNearbyPlace falls back to an empty array on failure", async () => {
    apiClient.utils.getNearbyPlaces.mockRejectedValueOnce(new Error("boom"));

    await useUtilsStore.getState().fetchNearbyPlace();

    expect(useUtilsStore.getState().nearbyPlaceData).toEqual([]);
  });
});
