import { collection, getDocs, query, where } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useAgentsStore = create((set) => ({
  list: [],
  isLoading: true,
  fetchAgentList: async () => {
    try {
      const q = query(collection(db, "users"), where("role", "==", "agent"));
      const querySnapshot = await getDocs(q);

      const agentList = await Promise.all(
        querySnapshot.docs.map(async (doc) => {
          const agentId = doc.id;

          const statsQuery = query(
            collection(db, "statistics"),
            where("agentId", "==", agentId),
            where("stage", "==", 1),
          );
          const statsSnapshot = await getDocs(statsQuery);

          const adsCount = statsSnapshot.size;

          return {
            id: agentId,
            ...doc.data(),
            adsCount,
          };
        }),
      );

      set({ list: agentList, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ list: [], isLoading: false });
    }
  },
}));
