import { create } from "zustand";
import { apiClient } from "./apiClient";

export const useStatisticsStore = create((set) => ({
  isLoading: true,
  adsNewCount: 0,
  adsSoldCount: 0,
  listCwrkST: [],
  // agentId param kept for call-site compatibility; the API scopes to the
  // caller's own agent context.
  getAdsStatistics: async (agentId, filterType) => {
    try {
      const data = await apiClient.statistics.getAdsStatistics(filterType);
      set({
        adsNewCount: data.adsNewCount,
        adsSoldCount: data.adsSoldCount,
        isLoading: false,
      });
    } catch (error) {
      console.error("Error fetching statistics:", error);
      set({ adsNewCount: 0, adsSoldCount: 0, isLoading: false });
    }
  },

  getCoworkerStatistics: async () => {
    try {
      const data = await apiClient.statistics.getCoworkerStatistics();
      set({ listCwrkST: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching statistics:", error);
      set({ listCwrkST: [], isLoading: false });
    }
  },
}));
