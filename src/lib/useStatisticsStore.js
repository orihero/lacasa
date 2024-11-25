import { collection, getDocs, query, where } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useStatisticsStore = create((set) => ({
  isLoading: true,
  adsNewCount: 0,
  adsSoldCount: 0,
  listCwrkST: [],
  getAdsStatistics: async (agentId, filterType) => {
    try {
      const now = new Date();
      let startDate, endDate;

      switch (filterType) {
        case "today": // Bugun
          startDate = new Date(now.setHours(0, 0, 0, 0)); // Kun boshi
          endDate = new Date(now.setHours(23, 59, 59, 999)); // Kun oxiri
          break;
        case "thisWeek": // Shu hafta
          // eslint-disable-next-line no-case-declarations
          const weekStart = now.getDate() - now.getDay(); // Haftaning bosh kuni
          startDate = new Date(now.setDate(weekStart));
          startDate.setHours(0, 0, 0, 0);
          endDate = new Date(startDate);
          endDate.setDate(startDate.getDate() + 6); // Haftaning oxiri
          endDate.setHours(23, 59, 59, 999);
          break;
        case "thisMonth": // Shu oy
          startDate = new Date(now.getFullYear(), now.getMonth(), 1); // Oyning boshi
          endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0); // Oyning oxiri
          endDate.setHours(23, 59, 59, 999);
          break;
        default: // "all" (hammasi)
          startDate = null;
          endDate = null;
          break;
      }

      const filters = [
        where("agentId", "==", agentId),
        where("stage", "==", 1),
      ];

      // Agar vaqt chegaralari mavjud bo'lsa, filterlarni qo'shamiz
      if (startDate && endDate) {
        filters.push(where("createdAt", ">=", startDate));
        filters.push(where("createdAt", "<=", endDate));
      }

      const stage1Query = query(collection(db, "statistics"), ...filters);

      const stage2Filters = [
        where("agentId", "==", agentId),
        where("stage", "==", 2),
      ];

      if (startDate && endDate) {
        stage2Filters.push(where("createdAt", ">=", startDate));
        stage2Filters.push(where("createdAt", "<=", endDate));
      }

      const stage2Query = query(collection(db, "statistics"), ...stage2Filters);

      const [stage1Snapshot, stage2Snapshot] = await Promise.all([
        getDocs(stage1Query),
        getDocs(stage2Query),
      ]);

      set({
        adsNewCount: stage1Snapshot.size, // Stage 1 - yangi e'lonlar
        adsSoldCount: stage2Snapshot.size, // Stage 2 - sotilgan e'lonlar
        isLoading: false,
      });
    } catch (error) {
      console.error("Error fetching statistics:", error);
      set({
        adsNewCount: 0,
        adsSoldCount: 0,
        isLoading: false,
      });
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
