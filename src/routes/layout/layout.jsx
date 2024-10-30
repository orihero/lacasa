import "./layout.scss";
import Navbar from "../../components/navbar/Navbar";
import { Outlet } from "react-router-dom";
import Notification from "../../components/notification/Notification";
import { useEffect } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "../../lib/firebase";
import { useUserStore } from "../../lib/userStore";
import Footer from "../../components/footer/Footer";
import { useListStore } from "../../lib/adsListStore";

function Layout() {
  const { fetchUserInfo } = useUserStore();
  const { fetchAdsList } = useListStore();
  useEffect(() => {
    fetchAdsList();
    const unSub = onAuthStateChanged(auth, (user) => {
      fetchUserInfo(user?.uid);
    });

    return () => {
      unSub();
    };
  }, []);

  return (
    <div className="layout">
      <div className="navbar">
        <Navbar />
      </div>
      <div className="content">
        <Outlet />
      </div>
      <Notification />
      <div className="footer">
        <Footer />
      </div>
    </div>
  );
}

export default Layout;
