import { doc, getDoc } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";
import { IGService } from "../services/ig";
import { TGService } from "../services/tg";

export const useUserStore = create((set) => ({
  currentUser: null,
  isLoading: true,
  agent: {},
  fetchUserInfo: async (uid) => {
    try {
      if (!uid) return set({ currentUser: null, isLoading: false });
      const docRef = doc(db, "users", uid);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const userData = docSnap.data();
        let igAccounts = [];
        let tgAccounts = [];
        let agentInfo = null;

        if (userData.role === "coworker" || userData.role === "agent") {
          // Agent ma'lumotlarini olish
          let agentId =
            userData.role === "agent" ? userData.id : userData.agentId;
          const agentRef = doc(db, "users", agentId);
          const agentSnap = await getDoc(agentRef);
          if (agentSnap.exists()) {
            const agentData = agentSnap.data();
            if (agentData?.igTokens && agentData?.tgChatIds) {
              igAccounts = await IGService.init(agentData?.igTokens);
              tgAccounts = await TGService.init(agentData?.tgChatIds);
            }

            agentInfo = {
              id: userData.agentId,
              ...agentData,
            };
          }
        }
        // else {
        //   // Foydalanuvchi o'z tokenlari bilan ish yuritadi
        //   // igAccounts = await IGService.init(userData?.igTokens);
        //   // tgAccounts = await TGService.init(userData?.tgChatIds);
        // }

        // console.log("====================================");
        // console.log({ igAccounts, tgAccounts });
        // console.log("====================================");

        set({
          currentUser: {
            ...userData,
            igAccounts,
            tgAccounts,
            tgChatIds: agentInfo?.tgChatIds,
            igTokens: agentInfo?.igTokens,
          },
          isLoading: false,
        });
      } else {
        set({ currentUser: null, isLoading: false });
      }
    } catch (error) {
      console.error(error);
      set({ currentUser: null, isLoading: false });
    }
  },

  logout: async () => {
    set({ currentUser: null, isLoading: false });
  },
  fetchUserById: async (id) => {
    try {
      const docRef = doc(db, "users", id);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const agentData = { id: docSnap.id, ...docSnap.data() };
        set({ agent: agentData, isLoading: false });
        console.log("Agent data:", agentData);
      } else {
        console.log("No such document!");
        set({ agent: null, isLoading: false });
      }
    } catch (error) {
      console.error("Error fetching document:", error);
      set({ agent: null, isLoading: false });
    }
  },
}));
