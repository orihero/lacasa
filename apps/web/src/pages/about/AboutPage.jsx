import React from "react";
import "./about.scss";
import TelegramIcon from "../../components/icons/TelegramIcon";
import { useTranslation } from "react-i18next";

const AboutPage = () => {
  const { t } = useTranslation();
  return (
    <div className="about">
      <div className="about-item">
        <div className="about-title">
          <h1>{t("one.title")}</h1>
        </div>
        <div className="about-content">
          <div className="item-text">
            <p>{t("one.text")}</p>
          </div>
          <div className="item-photo">
            <img src="/about2.webp" alt="" />
          </div>
        </div>
      </div>
      <div className="about-item reverse">
        <div className="about-title">
          <h1>{t("two.title")}</h1>
        </div>
        <div className="about-content">
          <div className="item-text">
            <p>{t("two.text")}</p>
          </div>
          <div className="item-photo">
            <img src="/about3.webp" alt="" />
          </div>
        </div>
      </div>
      <div className="about-item">
        <div className="about-title">
          <h1>{t("there.title")}</h1>
        </div>
        <div className="about-content">
          <div className="item-text">
            <p>{t("there.text")}</p>
          </div>
          <div className="item-photo">
            <img src="/about1.webp" alt="" />
          </div>
        </div>
      </div>
      <div className="about-item">
        <div className="about-title">
          <h1>{t("contactUs")}</h1>
        </div>
        <div className="about-content contact-content">
          <div className="item-text contact">
            <p>
              <img width={30} src="/icons/phone.svg" />
              <a href="tel:+998994480500">
                <b>+998 99 448 05 00</b>
              </a>
            </p>
            <p>
              <TelegramIcon width={30} />
              <a href="https://t.me/@orihero">
                <b>Telegram</b>
              </a>
            </p>
          </div>
          <div className="item-photo contact-img">
            <img src="/contact1.svg" alt="" />
          </div>
        </div>
      </div>
    </div>
  );
};

export default AboutPage;
