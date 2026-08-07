import { create } from "zustand";
import { apiClient } from "./apiClient";

export const useUtilsStore = create((set) => ({
  currency: [],
  nearbyPlaceData: [],
  isLoading: true,
  fetchCurrency: async () => {
    try {
      const data = await apiClient.utils.getCurrency();
      set({ currency: [{ id: data.code, currency: data.rate }], isLoading: false });
    } catch (error) {
      console.error("fetch currency", error);
      set({ currency: [], isLoading: false });
    }
  },
  fetchNearbyPlace: async () => {
    try {
      const data = await apiClient.utils.getNearbyPlaces();
      set({ nearbyPlaceData: [{ id: "nearby", data }], isLoading: false });
    } catch (error) {
      console.error("Error fetchNearbyPlace: ", error);
      set({ nearbyPlaceData: [], isLoading: false });
    }
  },
}));
