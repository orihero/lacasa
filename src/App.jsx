import { PrimeReactProvider } from "primereact/api";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import AboutPage from "./pages/about/AboutPage";
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
import AgentProfilePage from "./pages/agentProfilePage/AgentProfilePage";
import AdsList from "./components/adsList/AdsList";
import LeadList from "./components/leadList/LeadList";
import CoworkerList from "./components/coworkerList/CoworkerList";
import Chart from "./components/Chart/Chart";
import ProfileSetting from "./components/profileSetting/ProfileSetting";
import CoworkerAdd from "./components/coworkerAdd/CoworkerAdd";
import LeadAdd from "./components/leadAdd/leadAdd";
import AdsAdd from "./components/adsAdd/AdsAdd";

function App() {
  const router = createBrowserRouter([
    {
      path: "/",
      element: <Layout />,
      children: [
        {
          path: "/",
          element: <HomePage />,
        },
        {
          path: "/list",
          element: <ListPage />,
        },
        {
          path: "/about",
          element: <AboutPage />,
        },
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
              path: ":id/leads",
              element: <LeadList />,
            },
            {
              path: ":id/create/leads",
              element: <LeadAdd />,
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
