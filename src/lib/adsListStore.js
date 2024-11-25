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
  stageCount: { stage1: 0, stage2: 0 },
  isLoading: true,
  fetchAdsList: async () => {
    try {
      const adsQuery = query(collection(db, "ads"), where("stage", "==", "1"));
      const querySnapshot = await getDocs(adsQuery);
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
  fetchAdsByAgentId: async (agentId, filters = {}, sortOption = "newest") => {
    try {
      const adsRef = collection(db, "ads");

      const queries = [where("agentId", "==", agentId)];

      if (filters.city) {
        queries.push(where("city", "==", filters.city));
      }
      if (filters.district) {
        queries.push(where("district", "==", filters.district));
      }
      if (filters.category) {
        queries.push(where("category", "==", filters.category));
      }
      if (filters.type) {
        queries.push(where("type", "==", filters.type));
      }
      if (filters.rooms) {
        queries.push(where("rooms", "==", filters.rooms));
      }
      if (filters.repairment) {
        queries.push(where("repairment", "==", filters.repairment));
      }
      if (filters.storey) {
        queries.push(where("storey", "==", filters.storey));
      }
      if (filters.furniture) {
        queries.push(where("furniture", "==", filters.furniture));
      }
      if (filters.areaMin) {
        queries.push(where("area", ">=", filters.areaMin));
      }
      if (filters.areaMax) {
        queries.push(where("area", "<=", filters.areaMax));
      }
      if (filters.priceMin !== undefined) {
        queries.push(where("price", ">=", filters.priceMin));
      }
      if (filters.priceMax !== undefined) {
        queries.push(where("price", "<=", filters.priceMax));
      }

      // switch (sortOption) {
      //   case "highestPrice":
      //     queries.push(orderBy("price", "desc"));
      //     break;
      //   case "lowestPrice":
      //     queries.push(orderBy("price", "asc"));
      //     break;
      //   case "newest":
      //   default:
      //     queries.push(orderBy("createdAt", "desc"));
      //     break;
      // }

      const adsQuery = query(adsRef, ...queries);
      const querySnapshot = await getDocs(adsQuery);

      const adsList = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      console.log(adsList);

      set({ myList: adsList, isLoading: false });
    } catch (error) {
      console.error(error);
      set({ myList: [], isLoading: false });
    }
  },
  fetchAdsById: async (id) => {
    set({ adsData: {}, isLoading: true });
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
  fetchAdsByStage: async (agentId) => {
    try {
      const adsRef = collection(db, "ads");

      const adsQuery = query(adsRef, [where("agentId", "==", agentId)]);

      const querySnapshot = await getDocs(adsQuery);

      const adsList = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      let filterStage1 = adsList.filter((ad) => ad.stage == "1").length;
      let filterStage2 = adsList.filter((ad) => ad.stage == "2").length;

      console.log(adsList);
      set({
        stageCount: { stage1: filterStage1, stage2: filterStage2 },
        isLoading: false,
      });
    } catch (error) {
      console.error(error);
      set({ stage1Count: [], isLoading: false });
    }
  },
}));
