import { create } from "zustand";
import { apiClient } from "./apiClient";

export const useLeadStore = create((set) => ({
  list: [],
  isLoading: true,
  lead: {},
  isUpdated: false,
  // agentId param kept for call-site compatibility; the API scopes to the
  // caller's own agent context (see apps/api/src/routes/leads.js).
  fetchLeadList: async () => {
    try {
      const data = await apiClient.leads.list();
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching leads:", error);
      set({ list: [], isLoading: false });
    }
  },
  fetchLeadById: async (leadId) => {
    try {
      const data = await apiClient.leads.getById(leadId);
      set({ lead: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching lead by id:", error);
      set({ lead: null, isLoading: false });
    }
  },
  // Historically identical to fetchLeadList server-side (see docs/05 Phase D
  // notes) — kept as a distinct action only because LeadList.jsx references it.
  fetchLeadListByCwrk: async () => {
    try {
      const data = await apiClient.leads.list();
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching leads:", error);
      set({ list: [], isLoading: false });
    }
  },
  updateLeadById: async (leadId, updateData) => {
    set({ isUpdated: true });

    try {
      const filteredData = Object.fromEntries(
        Object.entries(updateData).filter(([, value]) => value !== undefined),
      );

      await apiClient.leads.update(leadId, filteredData);

      set({ isUpdated: false });
    } catch (error) {
      console.error("Error updating lead by id:", error);
      set({ isUpdated: false });
    }
  },
}));
