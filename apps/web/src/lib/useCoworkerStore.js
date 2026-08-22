import { create } from "zustand";
import { apiClient } from "./apiClient";

export const useCoworkerStore = create((set) => ({
  list: [],
  isLoading: true,
  coworker: {},
  // agentId param kept for call-site compatibility; the API derives the
  // effective agent scope from the auth token (agent -> own id, coworker ->
  // their agentId) rather than trusting a client-supplied id.
  fetchCoworkerList: async () => {
    try {
      const data = await apiClient.coworkers.list();
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching coworkers:", error);
      set({ list: [], isLoading: false });
    }
  },
  fetchCoworkerById: async (userId) => {
    try {
      const data = await apiClient.coworkers.getById(userId);
      set({ coworker: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching coworker:", error);
      set({ coworker: null, isLoading: false });
    }
  },
}));
