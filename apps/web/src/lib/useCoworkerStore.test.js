import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./apiClient";
import { useCoworkerStore } from "./useCoworkerStore";

vi.mock("./apiClient", () => ({
  apiClient: {
    coworkers: {
      list: vi.fn(),
      getById: vi.fn(),
    },
  },
}));

describe("useCoworkerStore", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useCoworkerStore.setState({ list: [], isLoading: true, coworker: {} });
  });

  it("fetchCoworkerList populates list from apiClient.coworkers.list()", async () => {
    apiClient.coworkers.list.mockResolvedValueOnce([{ id: "cw-1", fullName: "Ann" }]);

    await useCoworkerStore.getState().fetchCoworkerList();

    expect(apiClient.coworkers.list).toHaveBeenCalledWith();
    expect(useCoworkerStore.getState().list).toEqual([{ id: "cw-1", fullName: "Ann" }]);
    expect(useCoworkerStore.getState().isLoading).toBe(false);
  });

  it("fetchCoworkerList falls back to an empty list on failure", async () => {
    apiClient.coworkers.list.mockRejectedValueOnce(new Error("boom"));

    await useCoworkerStore.getState().fetchCoworkerList();

    expect(useCoworkerStore.getState().list).toEqual([]);
    expect(useCoworkerStore.getState().isLoading).toBe(false);
  });

  it("fetchCoworkerById populates coworker from apiClient.coworkers.getById()", async () => {
    apiClient.coworkers.getById.mockResolvedValueOnce({ id: "cw-1", fullName: "Ann" });

    await useCoworkerStore.getState().fetchCoworkerById("cw-1");

    expect(apiClient.coworkers.getById).toHaveBeenCalledWith("cw-1");
    expect(useCoworkerStore.getState().coworker).toEqual({ id: "cw-1", fullName: "Ann" });
  });

  it("fetchCoworkerById sets coworker to null on failure", async () => {
    apiClient.coworkers.getById.mockRejectedValueOnce(new Error("boom"));

    await useCoworkerStore.getState().fetchCoworkerById("cw-1");

    expect(useCoworkerStore.getState().coworker).toBeNull();
  });
});
