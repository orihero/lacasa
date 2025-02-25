import React from "react";
import "./hCard.scss";
import RoomsIcon from "../icons/RoomsIcon";
import LocationIcon from "../icons/LocationIcon";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";

function HorizontalCard({ data }) {
  const navigate = useNavigate();
  const { t } = useTranslation();

  const handleNavigate = (id) => {
    if (id.length) {
      navigate("/post/" + id);
    }
  };

  return (
    <div className="hCard" onClick={() => handleNavigate(data.id)}>
      {/* <ImageCarusel items={data.photos} /> */}
      <img src={data.photos[0]} />
      <div className="textContainer">
        <div className="badge">
          {/* <img src="/badge.png" /> */}
          <img src="/icons/stars.svg" alt="" className="icon" />
          <p>{data.category === "sale" ? t("sale") : t("rent")}</p>
        </div>
        <div className="price">
          <h2>
            {data.price?.length > 0 ? data.price : "-"}{" "}
            {data.priceType ?? "y.e"}
            {data.category === "rent" && (
              <span className="price-month">/{t("month")}</span>
            )}
          </h2>
          <h1>
            {data.title?.length > 15
              ? data.title?.slice(0, 15) + "..."
              : data.title}
          </h1>
        </div>
        <p className="address">
          {" "}
          {data.address.length > 25
            ? data.address?.slice(0, 25) + "..."
            : data.address}
        </p>
        <div className="line" />
        <div className="row">
          <div className="item">
            <LocationIcon width={20} height={20} fill="#7065f0" />
            <p>{data.city}</p>
          </div>
          <div className="item">
            {/* <img alt="" src="/icons/bed.svg" /> */}
            <RoomsIcon />
            <p>
              {data.rooms} {t("room")}
            </p>
          </div>
          <div className="item">
            <img alt="" src="/icons/meters.svg" />
            <p>
              {data.area.length > 0 ? data.area : "-"} m<sup>2</sup>
            </p>
          </div>
        </div>
      </div>
      <div className="footer-btn-actions">
        <button className="apply-btn-ads-card">{t("apply")}</button>
      </div>
    </div>
  );
}

export default HorizontalCard;
