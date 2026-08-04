import { PrimeReactProvider } from "primereact/api";
import { createBrowserRouter, Navigate, RouterProvider } from "react-router-dom";
import AdsAdd from "./components/adsAdd/AdsAdd.tsx";
import AdsList from "./components/adsList/AdsList";
import CoworkerAdd from "./components/coworkerAdd/CoworkerAdd";
import CoworkerList from "./components/coworkerList/CoworkerList";
import LeadList from "./components/leadList/LeadList";
import ProfileSetting from "./components/profileSetting/ProfileSetting";
import Layout from "./routes/layout/layout";
import Login from "./routes/login/login";
import ProfilePage from "./routes/profilePage/profilePage";
import ProfileUpdatePage from "./routes/profileUpdatePage/profileUpdatePage";
import Register from "./routes/register/register";
import LeadUpdate from "./components/leadUpdate/LeadUpdate";
import LeadAdd from "./components/leadAdd/LeadAdd";
import CoworkerUpdate from "./components/coworkerUpdate/CoworkerUpdate";
import LeadKanbanList from "./components/leadList/LeadKanbanList.tsx";
import Chart from "./components/chart/Chart.jsx";
import "./index.css";
import AdsEdit from "./components/adsEdit/AdsEdit.tsx";
import AboutPageNew from "./routes/aboutPageNew/AboutPageNew.jsx";
import MarketLayout from "./marketplace/MarketLayout";
import MarketHome from "./marketplace/pages/MarketHome";
import SearchPage from "./marketplace/pages/SearchPage";
import ListingDetailPage from "./marketplace/pages/ListingDetailPage";
import AgentsDirectoryPage from "./marketplace/pages/AgentsDirectoryPage";
import AgentPublicProfilePage from "./marketplace/pages/AgentPublicProfilePage";
import SavedPage from "./marketplace/pages/SavedPage";

function App() {
  const router = createBrowserRouter([
    // The buyer-facing marketplace — public, no auth required. Same data as
    // the mobile app's feed (GET /ads, /agents, /saved-ads), same liquid-
    // glass design language (mockups/web-user.html).
    {
      path: "/",
      element: <MarketLayout />,
      children: [
        {
          index: true,
          element: <MarketHome />,
        },
        {
          path: "list",
          element: <SearchPage />,
        },
        {
          path: "post/:id",
          element: <ListingDetailPage />,
        },
        {
          path: "agents",
          element: <AgentsDirectoryPage />,
        },
        {
          path: "agent/:id",
          element: <AgentPublicProfilePage />,
        },
        {
          path: "saved",
          element: <SavedPage />,
        },
        {
          // The legacy public-listings path, kept because the CRM navbar and
          // old bookmarks still point at it.
          path: "ads",
          element: <Navigate to="/list" replace />,
        },
      ],
    },
    // The CRM console and auth pages keep the legacy Layout chrome.
    {
      element: <Layout />,
      children: [
        {
          path: "/about",
          element: <AboutPageNew />,
        },
        {
          path: "/profile",
          element: <ProfilePage />,
          children: [
            {
              path: "",
              element: <Chart />,
            },
            {
              path: ":id/ads",
              element: <AdsList />,
            },
            {
              path: ":id/create/ads",
              element: <AdsAdd />,
            },
            {
              path: ":id/update/ads",
              element: <AdsEdit />,
            },
            {
              path: ":id/leads",
              element: <LeadList />,
            },
            {
              path: ":id/kanban",
              element: <LeadKanbanList />,
            },
            {
              path: ":id/create/leads",
              element: <LeadAdd />,
            },
            {
              path: ":id/update/leads",
              element: <LeadUpdate />,
            },
            {
              path: ":id/coworkers",
              element: <CoworkerList />,
            },
            {
              path: ":id/create/coworkers",
              element: <CoworkerAdd />,
            },
            {
              path: ":id/update/coworkers",
              element: <CoworkerUpdate />,
            },
            {
              path: ":id/setting",
              element: <ProfileSetting />,
            },
          ],
        },
        {
          path: "/updateProfile",
          element: <ProfileUpdatePage />,
        },
        {
          path: "/login",
          element: <Login />,
        },
        {
          path: "/register",
          element: <Register />,
        },
      ],
    },
  ]);

  return (
    <div style={{ overflow: "scroll", maxHeight: "100vh" }}>
      <PrimeReactProvider>
        <RouterProvider router={router} />
      </PrimeReactProvider>
    </div>
  );
}

export default App;
