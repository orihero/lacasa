import { useEffect } from "react";
import { Outlet } from "react-router-dom";
import Footer from "../../components/footer/Footer";
import Navbar from "../../components/navbar/Navbar";
import Notification from "../../components/notification/Notification";
import { useListStore } from "../../lib/adsListStore";
import { useUserStore } from "../../lib/userStore";
import "./layout.scss";

function Layout() {
  const { fetchUserInfo } = useUserStore();
  const { fetchAdsList } = useListStore();
  useEffect(() => {
    fetchAdsList();
    fetchUserInfo();
  }, [fetchAdsList, fetchUserInfo]);

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
