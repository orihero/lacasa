import React from "react";
import "./hCard.scss";
import ImageCarusel from "../ImageCarusel/ImageCarusel";
import RoomsIcon from "../icons/RoomsIcon";
import { useNavigate } from "react-router-dom";

function HorizontalCard({ data }) {
  const navigate = useNavigate();

  const handleNavigate = (id) => {
    if (id.length) {
      navigate("/post/" + id);
    }
  };

  return (
    <div className="hCard" onClick={() => handleNavigate(data.id)}>
      {/* <ImageCarusel items={data.photos} /> */}
      <img src={data.photos[0]} />
      <div className="badge">
        <img src="/badge.png" />
        <img src="/icons/stars.svg" alt="" className="icon" />
        <p>Popular</p>
      </div>
      <div className="textContainer">
        <div className="price">
          <h2>
            ${data.price.length > 0 ? data.price : "-"}
            <span>/month</span>
          </h2>
          <h1>
            {data.title.length > 15
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
            <img alt="" width={10} src="/icons/location.svg" />
            <p>{data.city}</p>
          </div>
          <div className="item">
            {/* <img alt="" src="/icons/bed.svg" /> */}
            <RoomsIcon />
            <p>{data.rooms} rooms</p>
          </div>
          <div className="item">
            <img alt="" src="/icons/meters.svg" />
            <p>
              {data.area.length > 0 ? data.area : "-"} m<sup>2</sup>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default HorizontalCard;
