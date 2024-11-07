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

export const useCoworkerStore = create((set) => ({
  list: [],
  isLoading: true,
  coworker: {},
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
  fetchCoworkerById: async (userId, agentId) => {
    try {
      const docRef = doc(db, "users", userId);
      const docSnap = await getDoc(docRef);

      const coworker =
        docSnap.exists() && docSnap.data().agentId === agentId
          ? { id: docSnap.id, ...docSnap.data() }
          : null;

      set({ coworker, isLoading: false });
    } catch (error) {
      console.error("Error fetching coworker:", error);
      set({ coworker: null, isLoading: false });
    }
  },
}));
