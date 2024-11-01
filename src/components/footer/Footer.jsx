import React from "react";
import "./footer.scss";
import InstagramIcon from "../icons/InstagramIcon";
import TelegramIcon from "../icons/TelegramIcon";
import { Link } from "react-router-dom";

const Footer = () => {
  return (
    <div className="footer">
      <div className="footer-list">
        <span className="links">
          <Link to="/">Home</Link>
          <Link to="/about">About</Link>
          {/* <Link to="/contact">Contact</Link> */}
          <Link to="/agents">Agents</Link>
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
