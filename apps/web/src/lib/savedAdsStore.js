import { create } from "zustand";
import { apiClient } from "./apiClient";
import { getAuthToken } from "./api";

// The buyer's favourites (the heart control). Mirrors the mobile app's
// contract (live_home_feed_repository.dart): a failed GET /saved-ads —
// typically `forbidden` for an agent/coworker session — degrades to "nothing
// saved" instead of breaking the page, and both writes are idempotent
// server-side, so toggles apply optimistically and roll back on error.
export const useSavedAdsStore = create((set, get) => ({
  savedIds: new Set(),
  savedList: [],
  isLoading: false,
  loaded: false,

  fetchSaved: async () => {
    if (!getAuthToken()) {
      set({ savedIds: new Set(), savedList: [], loaded: true, isLoading: false });
      return;
    }
    set({ isLoading: true });
    try {
      const list = await apiClient.savedAds.list();
      set({
        savedList: list,
        savedIds: new Set(list.map((ad) => ad.id)),
        loaded: true,
        isLoading: false,
      });
    } catch (error) {
      console.error(error);
      set({ savedIds: new Set(), savedList: [], loaded: true, isLoading: false });
    }
  },

  toggleSaved: async (adId) => {
    const { savedIds, savedList } = get();
    const wasSaved = savedIds.has(adId);

    const nextIds = new Set(savedIds);
    if (wasSaved) {
      nextIds.delete(adId);
    } else {
      nextIds.add(adId);
    }
    set({
      savedIds: nextIds,
      // On unsave, drop the row from the Saved page immediately; on save the
      // full row isn't known client-side — the next fetchSaved picks it up.
      savedList: wasSaved ? savedList.filter((ad) => ad.id !== adId) : savedList,
    });

    try {
      if (wasSaved) {
        await apiClient.savedAds.unsave(adId);
      } else {
        await apiClient.savedAds.save(adId);
      }
    } catch (error) {
      console.error(error);
      set({ savedIds: savedIds, savedList });
    }
  },
}));
