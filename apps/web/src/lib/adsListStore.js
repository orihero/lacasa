import { create } from "zustand";
import { api } from "./api";
import { useUserStore } from "./userStore";

export const useListStore = create((set) => ({
  list: [],
  myList: [],
  adsData: {},
  stageCount: { stage1: 0, stage2: 0 },
  isLoading: true,
  fetchAdsList: async () => {
    try {
      const { data } = await api.get("/ads");
      set({ list: data, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ list: [], isLoading: false });
    }
  },
  // Serves two callers with different auth contexts: the authenticated
  // agent/coworker dashboard (AdsList/Filter/Chart — needs every stage,
  // including drafts) and the public agent-profile page (AgentProfilePage —
  // anonymous visitors, active listings only). Route to /my/ads only when
  // the requested agentId matches the caller's own scope; otherwise fall
  // back to the public, active-only endpoint.
  fetchAdsByAgentId: async (agentId, filters = {}, sortOption = "newest") => {
    try {
      const params = {
        city: filters.city || undefined,
        district: filters.district || undefined,
        category: filters.category || undefined,
        type: filters.type || undefined,
        rooms: filters.rooms || undefined,
        repairment: filters.repairment || undefined,
        storey: filters.storey || undefined,
        furniture: filters.furniture || undefined,
        areaMin: filters.areaMin || undefined,
        areaMax: filters.areaMax || undefined,
        priceMin: filters.priceMin !== "" ? filters.priceMin : undefined,
        priceMax: filters.priceMax !== "" ? filters.priceMax : undefined,
        sort: sortOption,
      };

      const { currentUser } = useUserStore.getState();
      const myScopeId =
        currentUser?.role === "agent"
          ? currentUser.id
          : currentUser?.role === "coworker"
            ? currentUser.agentId
            : null;

      const { data } =
        myScopeId && myScopeId === agentId
          ? await api.get("/my/ads", { params })
          : await api.get("/ads", { params: { ...params, agentId } });

      set({ myList: data, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ myList: [], isLoading: false });
    }
  },
  fetchAdsById: async (id) => {
    set({ adsData: {}, isLoading: true });
    try {
      const { data } = await api.get(`/ads/${id}`);
      set({ adsData: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching ad by ID: ", error);
      set({ adsData: {}, isLoading: false });
    }
  },
  fetchAdsByStage: async () => {
    try {
      const { data } = await api.get("/my/ads/stage-counts");
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
