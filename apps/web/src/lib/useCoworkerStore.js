import { create } from "zustand";
import { api } from "./api";

export const useCoworkerStore = create((set) => ({
  list: [],
  isLoading: true,
  coworker: {},
  // agentId param kept for call-site compatibility; the API derives the
  // effective agent scope from the auth token (agent -> own id, coworker ->
  // their agentId) rather than trusting a client-supplied id.
  fetchCoworkerList: async () => {
    try {
      const { data } = await api.get("/coworkers");
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching coworkers:", error);
      set({ list: [], isLoading: false });
    }
  },
  fetchCoworkerById: async (userId) => {
    try {
      const { data } = await api.get(`/coworkers/${userId}`);
      set({ coworker: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching coworker:", error);
      set({ coworker: null, isLoading: false });
    }
  },
}));
