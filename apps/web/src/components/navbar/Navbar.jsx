import { useCallback, useState } from "react";
import { Link } from "react-router-dom";
import { useUserStore } from "../../lib/userStore";
import "./navbar.scss";
import { Triangle } from "react-loader-spinner";
import { useTranslation } from "react-i18next";

function Navbar() {
  const [open, setOpen] = useState(false);
  const { t, i18n } = useTranslation();

  const { currentUser, isLoading } = useUserStore();

  const handleChangeLang = (lang) => {
    i18n.changeLanguage(lang);
  };

  const renderRight = useCallback(() => {
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

    if (currentUser) {
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
  }, [currentUser, isLoading]);

  return (
    <nav>
      <div className="left">
        <a href="/" className="logo">
          <img
            style={{ width: "50px", height: "50px" }}
            src="/logo.svg"
            alt=""
          />
          <span>Lacasa</span>
        </a>
        <Link to="/">{t("home")}</Link>
        {/* <Link   to="#about" id="about">
          {t("about")}
        </Link> */}
        {/* <a href="#about">{t("about")}</a> */}
        <Link to="/agents">{t("agents")}</Link>
        <Link to="/ads">{t("ads")}</Link>
      </div>
      <div className="right">
        <div className="lang">
          <select onChange={(e) => handleChangeLang(e.target.value)}>
            <option value="en" defaultChecked>
              En
            </option>
            <option value="uz">Uz</option>
            <option value="ru">Ru</option>
          </select>
        </div>
        {renderRight()}
        <div className="menuIcon">
          <img
            src="/menu.png"
            alt=""
            onClick={() => setOpen((prev) => !prev)}
          />
        </div>
        <div className={open ? "menu active" : "menu"}>
          <a href="/">{t("home")}</a>
          <a href="/home#about">{t("about")}</a>
          <a href="/agents">{t("agents")}</a>
          <a href="/login">{t("signIn")}</a>
          <a href="/register">{t("signUp")}</a>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
