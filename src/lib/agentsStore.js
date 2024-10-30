import { collection, getDocs } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useAgentsStore = create((set) => ({
  list: [],
  isLoading: true,
  fetchAgentList: async () => {
    try {
      const querySnapshot = await getDocs(collection(db, "agents"));
      const adsList = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ list: adsList, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ list: [], isLoading: false });
    }
  },
}));
