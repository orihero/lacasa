import { doc, getDoc } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

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
        set({ currentUser: docSnap.data(), isLoading: false });
        console.log(docSnap.data());
        console.log("SNAP");
      } else {
        set({ currentUser: null, isLoading: false });
      }
    } catch (error) {
      console.error(error);
      return set({ currentUser: null, isLoading: false });
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
