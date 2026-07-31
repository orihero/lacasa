import { create } from "zustand";
import { api } from "./api";

export const useAgentsStore = create((set) => ({
  list: [],
  isLoading: true,
  fetchAgentList: async () => {
    try {
      const { data } = await api.get("/agents");
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ list: [], isLoading: false });
    }
  },
}));
