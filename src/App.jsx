import { PrimeReactProvider } from "primereact/api";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import AdsAdd from "./components/adsAdd/AdsAdd.tsx";
import AdsList from "./components/adsList/AdsList";
import CoworkerAdd from "./components/coworkerAdd/CoworkerAdd";
import CoworkerList from "./components/coworkerList/CoworkerList";
import LeadList from "./components/leadList/LeadList";
import ProfileSetting from "./components/profileSetting/ProfileSetting";
import AboutPage from "./pages/about/AboutPage";
import AgentProfilePage from "./pages/agentProfilePage/AgentProfilePage";
import AgentsPage from "./pages/agents/AgentsPage";
import HomePage from "./routes/homePage/homePage";
import Layout from "./routes/layout/layout";
import ListPage from "./routes/listPage/listPage";
import Login from "./routes/login/login";
import NewPostPage from "./routes/newPostPage/newPostPage";
import ProfilePage from "./routes/profilePage/profilePage";
import ProfileUpdatePage from "./routes/profileUpdatePage/profileUpdatePage";
import Register from "./routes/register/register";
import SinglePage from "./routes/singlePage/singlePage";
import LeadUpdate from "./components/leadUpdate/LeadUpdate";
import LeadAdd from "./components/leadAdd/LeadAdd";
import CoworkerUpdate from "./components/coworkerUpdate/CoworkerUpdate";
import LeadKanbanList from "./components/leadList/LeadKanbanList.tsx";
import Chart from "./components/chart/Chart.jsx";
import "./index.css";
import AdsEdit from "./components/adsEdit/AdsEdit.tsx";
import AboutPageNew from "./routes/aboutPageNew/AboutPageNew.jsx";
function App() {
  const router = createBrowserRouter([
    {
      path: "/",
      element: <Layout />,
      children: [
        {
          path: "/",
          element: <AboutPageNew />,
        },
        {
          path: "/ads",
          element: <HomePage />,
        },
        {
          path: "/list",
          element: <ListPage />,
        },
        // {
        //   path: "/about",
        //   element: <AboutPageNew />,
        // },
        {
          path: "/agent/:id",
          element: <AgentProfilePage />,
        },
        {
          path: "/agents",
          element: <AgentsPage />,
        },
        {
          path: "/post/:id",
          element: <SinglePage />,
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
          path: "/post",
          element: <NewPostPage />,
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
