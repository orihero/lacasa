import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
} from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useListStore = create((set) => ({
  list: [],
  myList: [],
  adsData: {},
  isLoading: true,
  fetchAdsList: async () => {
    try {
      const querySnapshot = await getDocs(collection(db, "ads"));
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
  fetchAdsByAgentId: async (agentId) => {
    try {
      const adsRef = collection(db, "ads");
      const q = query(adsRef, where("agentId", "==", agentId));

      const querySnapshot = await getDocs(q);

      const adsData = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ myList: adsData, isLoading: false });
    } catch (error) {
      console.error("Error fetching ads by agent ID: ", error);
      set({ myList: [], isLoading: false });
    }
  },
  fetchAdsById: async (id) => {
    try {
      const adRef = doc(db, "ads", id);
      const docSnap = await getDoc(adRef);

      if (docSnap.exists()) {
        const adData = { id: docSnap.id, ...docSnap.data() };
        set({ adsData: adData, isLoading: false });
      } else {
        set({ adsData: {}, isLoading: false });
      }
    } catch (error) {
      console.error("Error fetching ad by ID: ", error);
      set({ adsData: {}, isLoading: false });
    }
  },
}));
