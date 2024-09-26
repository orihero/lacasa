import React from "react";
import "./hCard.scss";
import { Link } from "react-router-dom";

function HorizontalCard() {
  return (
    <Link to={`/21`}>
      <div className="hCard">
        <img
          src="https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"
          alt=""
        />
        <div className="badge">
          <img src="/badge.png" />
          <img src="/icons/stars.svg" alt="" className="icon" />
          <p>Popular</p>
        </div>
        <div className="textContainer">
          <div className="price">
            <h2>
              $2,095<span>/month</span>
            </h2>
            <h1>Palm Harbor</h1>
          </div>
          <p className="address">2699 Green Valley, Highland Lake, FL</p>
          <div className="line" />
          <div className="row">
            <div className="item">
              <img alt="" src="/icons/bed.svg" />
              <p>3 beds</p>
            </div>
            <div className="item">
              <img alt="" src="/icons/bath.svg" />
              <p>2 bathrooms</p>
            </div>
            <div className="item">
              <img alt="" src="/icons/meters.svg" />
              <p>
                5x7 m<sup>2</sup>
              </p>
            </div>
          </div>
        </div>
      </div>
    </Link>
  );
}

export default HorizontalCard;
