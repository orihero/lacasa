import { create } from "zustand";
import { apiClient } from "./apiClient";

export const useAgentsStore = create((set) => ({
  list: [],
  isLoading: true,
  fetchAgentList: async () => {
    try {
      const data = await apiClient.agents.list();
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ list: [], isLoading: false });
    }
  },
}));
