import HomePage from "./routes/homePage/homePage";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import ListPage from "./routes/listPage/listPage";
import Layout from "./routes/layout/layout";
import SinglePage from "./routes/singlePage/singlePage";
import ProfilePage from "./routes/profilePage/profilePage";
import NewPostPage from "./routes/newPostPage/newPostPage";
import ProfileUpdatePage from "./routes/profileUpdatePage/profileUpdatePage";
import Login from "./routes/login/login";
import Register from "./routes/register/register";
import AboutPage from "./pages/about/AboutPage";
import ContactPage from "./pages/contact/ContactPage";
import AgentsPage from "./pages/agents/AgentsPage";
import { PrimeReactProvider } from "primereact/api";

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
        // {
        //   path: "/contact",
        //   element: <ContactPage />,
        // },
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
