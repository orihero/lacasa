import { useState } from "react";
import { Link } from "react-router-dom";
import { useUserStore } from "../../lib/userStore";
import "./navbar.scss";
import { Triangle } from "react-loader-spinner";
import { useTranslation } from "react-i18next";

function Navbar() {
  const [open, setOpen] = useState(false);
  const { t, i18n } = useTranslation();

  const { currentUser, isLoading } = useUserStore();
  console.log(currentUser);

  const handleChangeLang = (lang) => {
    i18n.changeLanguage(lang);
  };

  const renderRight = () => {
    if (isLoading) {
      return (
        <Triangle
          visible={true}
          height="80"
          width="80"
          color="#4fa94d"
          ariaLabel="triangle-loading"
          wrapperStyle={{}}
          wrapperClass=""
        />
      );
    }
    if (!!currentUser) {
      return (
        <div className="user">
          <img
            src={currentUser.avatar ? currentUser.avatar : "/avatar.jpg"}
            alt=""
          />
          <span>{currentUser.fullName}</span>
          <Link to="/profile" className="profile">
            {/* <div className="notification">3</div> */}
            <span>{t("profile")}</span>
          </Link>
        </div>
      );
    }

    return (
      <>
        <a href="/login">{t("signIn")}</a>
        <a href="/register" className="register">
          {t("signUp")}
        </a>
      </>
    );
  };

  return (
    <nav>
      <div className="left">
        <a href="/" className="logo">
          <img src="/logo.png" alt="" />
          <span>LamaEstate</span>
        </a>
        <Link to="/">{t("home")}</Link>
        <Link to="/about">{t("about")}</Link>
        {currentUser?.role == "agent" ? (
          <></>
        ) : (
          <>
            <Link to="/agents">{t("agents")}</Link>
          </>
        )}
      </div>
      <div className="right">
        {renderRight()}
        <div className="lang">
          <select onChange={(e) => handleChangeLang(e.target.value)}>
            <option value="uz">Uz</option>
            <option value="ru">Ru</option>
            <option value="en">En</option>
          </select>
        </div>
        {/* {!!currentUser ? (
          <div className="user">
            <img
              src={currentUser.avatar ? currentUser.avatar : "/avatar.jpg"}
              alt=""
            />
            <span>{currentUser.fullName}</span>
            <Link to="/profile" className="profile">
              <div className="notification">3</div>
              <span>Profile</span>
            </Link>
          </div>
        ) : (
          <>
            {isLoading ? (
              <Triangle
                visible={true}
                height="80"
                width="80"
                color="#4fa94d"
                ariaLabel="triangle-loading"
                wrapperStyle={{}}
                wrapperClass=""
              />
            ) : (
              <>
                <a href="/login">Sign in</a>
                <a href="/register" className="register">
                  Sign up
                </a>
              </>
            )}
          </>
        )} */}
        <div className="menuIcon">
          <img
            src="/menu.png"
            alt=""
            onClick={() => setOpen((prev) => !prev)}
          />
        </div>
        <div className={open ? "menu active" : "menu"}>
          <a href="/">Home</a>
          <a href="/">About</a>
          <a href="/">Contact</a>
          <a href="/">Agents</a>
          <a href="/">Sign in</a>
          <a href="/">Sign up</a>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
