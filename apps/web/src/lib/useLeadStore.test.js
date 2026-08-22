import { beforeEach, describe, expect, it, vi } from "vitest";
import { apiClient } from "./apiClient";
import { useLeadStore } from "./useLeadStore";

vi.mock("./apiClient", () => ({
  apiClient: {
    leads: {
      list: vi.fn(),
      getById: vi.fn(),
      update: vi.fn(),
    },
  },
}));

describe("useLeadStore", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useLeadStore.setState({ list: [], isLoading: true, lead: {}, isUpdated: false });
  });

  it("fetchLeadList populates list from apiClient.leads.list()", async () => {
    apiClient.leads.list.mockResolvedValueOnce([{ id: "lead-1", fullName: "Bob" }]);

    await useLeadStore.getState().fetchLeadList();

    expect(useLeadStore.getState().list).toEqual([{ id: "lead-1", fullName: "Bob" }]);
    expect(useLeadStore.getState().isLoading).toBe(false);
  });

  it("fetchLeadById populates lead from apiClient.leads.getById()", async () => {
    apiClient.leads.getById.mockResolvedValueOnce({ id: "lead-1" });

    await useLeadStore.getState().fetchLeadById("lead-1");

    expect(apiClient.leads.getById).toHaveBeenCalledWith("lead-1");
    expect(useLeadStore.getState().lead).toEqual({ id: "lead-1" });
  });

  it("fetchLeadById sets lead to null on failure", async () => {
    apiClient.leads.getById.mockRejectedValueOnce(new Error("boom"));

    await useLeadStore.getState().fetchLeadById("lead-1");

    expect(useLeadStore.getState().lead).toBeNull();
  });

  it("updateLeadById strips undefined fields before calling apiClient.leads.update()", async () => {
    apiClient.leads.update.mockResolvedValueOnce({ id: "lead-1" });

    await useLeadStore.getState().updateLeadById("lead-1", {
      status: "accepted",
      comment: undefined,
    });

    expect(apiClient.leads.update).toHaveBeenCalledWith("lead-1", { status: "accepted" });
    expect(useLeadStore.getState().isUpdated).toBe(false);
  });

  it("updateLeadById clears isUpdated even when the request fails", async () => {
    apiClient.leads.update.mockRejectedValueOnce(new Error("boom"));

    await useLeadStore.getState().updateLeadById("lead-1", { status: "accepted" });

    expect(useLeadStore.getState().isUpdated).toBe(false);
  });
});
