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
  // Serves two callers with different auth contexts: the authenticated
  // agent/coworker dashboard (AdsList/Filter/Chart — needs every stage,
  // including drafts) and the public agent-profile page (AgentProfilePage —
  // anonymous visitors, active listings only). The caller says which scope
  // it means explicitly — this store no longer reaches into useUserStore's
  // getState() to guess.
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
