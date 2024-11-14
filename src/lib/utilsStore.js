import { collection, getDocs } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useUtilsStore = create((set) => ({
  currency: [],
  nearbyPlaceData: [],
  isLoading: true,
  fetchCurrency: async () => {
    try {
      const querySnapshot = await getDocs(collection(db, "currency"));
      const currency = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      set({ currency: currency, isLoading: false });
    } catch (error) {
      console.error("fetch currency", error);
      set({ currency: [], isLoading: false });
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
      set({ nearbyPlaceData: [], isLoading: false });
    }
  },
}));
