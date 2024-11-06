import {
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  where,
} from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useLeadStore = create((set) => ({
  list: [],
  isLoading: true,
  fetchLeadList: async (agentId) => {
    try {
      const leadsQuery = query(
        collection(db, "leads"),
        where("agentId", "==", agentId),
      );

      const querySnapshot = await getDocs(leadsQuery);
      const leadsList = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ list: leadsList, isLoading: false });
    } catch (error) {
      console.error("Error fetching leads:", error);
      set({ list: [], isLoading: false });
    }
  },

  // fetchAdsById: async (id) => {
  //   try {
  //     const adRef = doc(db, "ads", id);
  //     const docSnap = await getDoc(adRef);

  //     if (docSnap.exists()) {
  //       const adData = { id: docSnap.id, ...docSnap.data() };
  //       set({ adsData: adData, isLoading: false });
  //     } else {
  //       set({ adsData: {}, isLoading: false });
  //     }
  //   } catch (error) {
  //     console.error("Error fetching ad by ID: ", error);
  //     set({ adsData: {}, isLoading: false });
  //   }
  // },
}));
