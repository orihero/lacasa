import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  updateDoc,
  where,
} from "firebase/firestore";
import { create } from "zustand";
import { db } from "./firebase";

export const useLeadStore = create((set) => ({
  list: [],
  isLoading: true,
  lead: {},
  isUpdated: false,
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
  fetchLeadById: async (leadId) => {
    try {
      const leadRef = doc(db, "leads", leadId);
      const leadDoc = await getDoc(leadRef);

      if (leadDoc.exists()) {
        const leadData = { id: leadDoc.id, ...leadDoc.data() };
        set({ lead: leadData, isLoading: false });
      } else {
        console.error("Lead not found");
        set({ lead: null, isLoading: false });
      }
    } catch (error) {
      console.error("Error fetching lead by id:", error);
      set({ lead: null, isLoading: false });
    }
  },
  fetchLeadListByCwrk: async (coworkerId) => {
    try {
      const leadsQuery = query(
        collection(db, "leads"),
        where("coworkerId", "==", coworkerId),
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
  updateLeadById: async (leadId, updateData) => {
    set({ isUpdated: true });

    try {
      const leadRef = doc(db, "leads", leadId);

      const filteredData = Object.fromEntries(
        Object.entries(updateData).filter(([_, value]) => value !== undefined),
      );

      await updateDoc(leadRef, filteredData);

      console.log("Lead successfully updated");
      set({ isUpdated: false });
    } catch (error) {
      console.error("Error updating lead by id:", error);
      set({ isUpdated: false });
    }
  },
}));
