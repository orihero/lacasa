import { useEffect } from "react";
import { Link, NavLink, Outlet } from "react-router-dom";
import { House, UserRound } from "lucide-react";
import { useUserStore } from "../lib/userStore";
import { useSavedAdsStore } from "../lib/savedAdsStore";
import "./marketplace.scss";

// Chrome for the buyer-facing marketplace (mockups/web-user.html). The CRM
// keeps its own Layout/Navbar; nothing here is role-gated — signed-out
// visitors browse everything, and the session only decides the top-right
// corner (Sign in vs. avatar) and whether hearts persist.
function MarketLayout() {
  const { currentUser, fetchUserInfo } = useUserStore();
  const { fetchSaved } = useSavedAdsStore();

  useEffect(() => {
    fetchUserInfo();
    fetchSaved();
  }, [fetchUserInfo, fetchSaved]);

  return (
    <div className="mkt">
      <header className="nav">
        <div className="wrap nav__in">
          <Link to="/" className="logo">
            <span className="logo__m">
              <House size={16} strokeWidth={2.4} />
            </span>
            La Casa
          </Link>
          <nav className="nav__links">
            <NavLink to="/" end className={({ isActive }) => (isActive ? "is-active" : "")}>
              Home
            </NavLink>
            <NavLink to="/list" className={({ isActive }) => (isActive ? "is-active" : "")}>
              Search
            </NavLink>
            <NavLink to="/agents" className={({ isActive }) => (isActive ? "is-active" : "")}>
              Agents
            </NavLink>
            <NavLink to="/saved" className={({ isActive }) => (isActive ? "is-active" : "")}>
              Saved
            </NavLink>
          </nav>
          <div className="nav__sp" />
          {currentUser ? (
            <Link
              to="/profile"
              className="avatar"
              title={currentUser.fullName}
              style={
                currentUser.avatar
                  ? { backgroundImage: `url(${currentUser.avatar})` }
                  : undefined
              }
            >
              {!currentUser.avatar && <UserRound size={18} />}
            </Link>
          ) : (
            <Link to="/login" className="btn btn--dark">
              Sign in
            </Link>
          )}
        </div>
      </header>

      <Outlet />

      <div className="wrap">
        <div className="foot">
          <span>© {new Date().getFullYear()} La Casa · Tashkent</span>
          <span>Every listing is published by a verified La Casa agent</span>
        </div>
      </div>
    </div>
  );
}

export default MarketLayout;
