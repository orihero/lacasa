import React from "react";
import "./footer.scss";
import InstagramIcon from "../icons/InstagramIcon";
import TelegramIcon from "../icons/TelegramIcon";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";

const Footer = () => {
  const { t } = useTranslation();

  return (
    <div className="footer">
      <div className="footer-list">
        <span className="links">
          <Link to="/">{t("home")}</Link>
          <Link to="/about">{t("about")}</Link>
          {/* <Link to="/contact">Contact</Link> */}
          <Link to="/agents">{t("agents")}</Link>
        </span>
        <span className="social-icons">
          <a href="/" target="_blank" title="instagram">
            <InstagramIcon width={25} fill="#fff" />
          </a>
          <a href="/" target="_blank" title="telegram">
            <TelegramIcon width={25} fill="#fff" />
          </a>
        </span>
      </div>
      <hr className="hr-line" />
      <div className="footer-copyright">
        <span>
          <p>&copy; Empire-soft - 2024</p>
        </span>
        <span>
          <img src="/logo.png" alt="" />
        </span>
      </div>
    </div>
  );
};

export default Footer;
