import { create } from "zustand";
import { apiClient } from "./apiClient";

export const useListStore = create((set) => ({
  list: [],
  myList: [],
  adsData: {},
  stageCount: { stage1: 0, stage2: 0 },
  isLoading: true,
  fetchAdsList: async () => {
    try {
      const data = await apiClient.ads.list();
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ list: [], isLoading: false });
    }
  },
  // Serves the authenticated agent/coworker dashboard (AdsList/Filter/
  // Chart — needs every stage, including drafts). The public agent-profile
  // page moved to the marketplace surface, which calls
  // apiClient.ads.getAds({ scope: "public" }) directly; the scope parameter
  // stays explicit here rather than reaching into useUserStore's getState()
  // to guess.
  fetchAdsByAgentId: async (agentId, filters = {}, sortOption = "newest", scope = "public") => {
    try {
      const data = await apiClient.ads.getAds({ scope, agentId, filters, sort: sortOption });
      set({ myList: data, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ myList: [], isLoading: false });
    }
  },
  fetchAdsById: async (id) => {
    set({ adsData: {}, isLoading: true });
    try {
      const data = await apiClient.ads.getById(id);
      set({ adsData: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching ad by ID: ", error);
      set({ adsData: {}, isLoading: false });
    }
  },
  fetchAdsByStage: async () => {
    try {
      const data = await apiClient.ads.getStageCounts();
      set({
        stageCount: { stage1: data.stage1, stage2: data.stage2 },
        isLoading: false,
      });
    } catch (error) {
      console.error(error);
      set({ stageCount: { stage1: 0, stage2: 0 }, isLoading: false });
    }
  },
}));
