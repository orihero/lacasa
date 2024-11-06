import { collection, getDocs, query, where } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useCoworkerStore = create((set) => ({
  list: [],
  isLoading: true,
  fetchCoworkerList: async (agentId) => {
    try {
      const usersQuery = query(
        collection(db, "users"),
        where("agentId", "==", agentId),
      );

      const querySnapshot = await getDocs(usersQuery);
      const usersList = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ list: usersList, isLoading: false });
    } catch (error) {
      console.error("Error fetching users:", error);
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
