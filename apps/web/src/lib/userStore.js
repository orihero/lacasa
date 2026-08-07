import { create } from "zustand";
import { apiClient } from "./apiClient";
import { getAuthToken, setAuthToken } from "./api";
import { TGService } from "../services/tg";

// GET /auth/me — the session read itself, nothing else. Enrichment of the
// raw user record (Telegram/Instagram account details) is each its own
// function below, orchestrated by fetchUserInfo.
async function loadSession() {
  const { user } = await apiClient.auth.me();
  return user;
}

// Telegram chat ids aren't secret, so resolving them into displayable
// channel info (title, avatar) still happens client-side via TGService.
// Moving this server-side is tracked separately — left as-is here.
async function enrichTelegramAccounts(userData) {
  if (!userData.tgChatIds?.length) return [];
  return TGService.init(userData.tgChatIds);
}

// userData.igAccounts already comes from the server as connected-account
// metadata (no access tokens ever reach the client) — this just backfills
// richer profile info (avatar, follower counts) via the server-side Graph
// API proxy. Falls back to the un-enriched accounts on any failure.
async function enrichInstagramAccounts(userData) {
  if (!userData.igAccounts?.length) return userData.igAccounts;
  try {
    const { accounts } = await apiClient.publish.getInstagramAccounts();
    return accounts?.length ? accounts : userData.igAccounts;
  } catch (error) {
    console.error("Failed to enrich IG accounts:", error);
    return userData.igAccounts;
  }
}

export const useUserStore = create((set) => ({
  currentUser: null,
  isLoading: true,
  agent: {},

  fetchUserInfo: async () => {
    if (!getAuthToken()) {
      return set({ currentUser: null, isLoading: false });
    }
    try {
      const userData = await loadSession();

      const [tgAccounts, igAccounts] = await Promise.all([
        enrichTelegramAccounts(userData),
        enrichInstagramAccounts(userData),
      ]);

      set({
        currentUser: { ...userData, tgAccounts, igAccounts },
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
      const data = await apiClient.agents.getById(id);
      set({ agent: data, isLoading: false });
    } catch (error) {
      console.error("Error fetching agent:", error);
      set({ agent: null, isLoading: false });
    }
  },
}));
