import { collection, getDocs } from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useListStore = create((set) => ({
  list: [],
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
}));
