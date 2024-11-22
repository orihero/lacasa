import { collection, getDocs, query, where } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useStatisticsStore = create((set) => ({
  isLoading: true,
  adsNewCount: 0,
  adsSoldCount: 0,
  listCwrkST: [],
  getAdsStatistics: async (agentId) => {
    try {
      const stage1Query = query(
        collection(db, "statistics"),
        where("agentId", "==", agentId),
        where("stage", "==", 1),
      );

      const stage2Query = query(
        collection(db, "statistics"),
        where("agentId", "==", agentId),
        where("stage", "==", 2),
      );

      const [stage1Snapshot, stage2Snapshot] = await Promise.all([
        getDocs(stage1Query),
        getDocs(stage2Query),
      ]);

      const stage1List = stage1Snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      const stage2List = stage2Snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({
        adsNewCount: stage1List?.length,
        adsSoldCount: stage2List?.length,
        isLoading: false,
      });
    } catch (error) {
      console.error("Error fetching statistics:", error);
      set({ stage1List: [], stage2List: [], isLoading: false });
    }
  },

  getCoworkerStatistics: async (agentId) => {
    try {
      const statsQuery = query(
        collection(db, "statistics"),
        where("agentId", "==", agentId),
      );

      const querySnapshot = await getDocs(statsQuery);

      const statsList = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ listCwrkST: statsList, isLoading: false });
    } catch (error) {
      console.error("Error fetching statistics:", error);
      set({ listCwrkST: [], isLoading: false });
    }
  },
}));
