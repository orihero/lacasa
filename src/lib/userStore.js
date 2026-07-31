import { create } from "zustand";
import { api, getAuthToken, setAuthToken } from "./api";
import { TGService } from "../services/tg";

export const useUserStore = create((set) => ({
  currentUser: null,
  isLoading: true,
  agent: {},

  fetchUserInfo: async () => {
    if (!getAuthToken()) {
      return set({ currentUser: null, isLoading: false });
    }
    try {
      const { data } = await api.get("/auth/me");
      const userData = data.user;

      // userData.igAccounts already comes from the server as connected-account
      // metadata (no access tokens ever reach the client); only Telegram
      // still needs a client-side resolve call, since chat ids aren't secret.
      let tgAccounts = [];
      if (userData.tgChatIds?.length) tgAccounts = await TGService.init(userData.tgChatIds);

      // Enrich IG accounts with profile info (avatar, follower counts) — the
      // server proxies the Graph API call with the stored token.
      if (userData.igAccounts?.length) {
        try {
          const { data: acc } = await api.get("/publish/instagram/accounts");
          if (acc.accounts?.length) userData.igAccounts = acc.accounts;
        } catch (e) {
          console.error("Failed to enrich IG accounts:", e);
        }
      }

      set({
        currentUser: { ...userData, tgAccounts },
        isLoading: false,
      });
    } catch (error) {
      console.error(error);
      setAuthToken(null);
      set({ currentUser: null, isLoading: false });
    }
  },

  logout: () => {
    setAuthToken(null);
    set({ currentUser: null, isLoading: false });
  },

  fetchUserById: async (id) => {
    try {
      const { data } = await api.get(`/agents/${id}`);
      set({ agent: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching agent:", error);
      set({ agent: null, isLoading: false });
    }
  },
}));
