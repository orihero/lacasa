import { collection, getDocs } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useUtilsStore = create((set) => ({
  curs: [],
  nearbyPlaceData: [],
  isLoading: true,
  fetchCurs: async () => {
    try {
      const querySnapshot = await getDocs(collection(db, "curs"));
      const curs = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ curs: curs, isLoading: false });
    } catch (error) {
      console.error("fetchCurs", error);
      set({ list: [], isLoading: false });
    }
  },
  fetchNearbyPlace: async () => {
    try {
      const querySnapshot = await getDocs(collection(db, "nearbyList"));
      const nearbyPlaceData = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ nearbyPlaceData: nearbyPlaceData, isLoading: false });
    } catch (error) {
      console.error("Error fetchNearbyPlace: ", error);
      set({ myList: [], isLoading: false });
    }
  },
}));
