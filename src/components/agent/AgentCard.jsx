import React from "react";
import { useNavigate } from "react-router-dom";
import InstagramIcon from "./../../components/icons/InstagramIcon";
import TelegramIcon from "./../../components/icons/TelegramIcon";
import WebIcon from "./../../components/icons/WebIcon";
import "./agentCard.scss";

const AgentCard = ({ agent }) => {
  const navigate = useNavigate();

  const handleNavigate = (id) => {
    navigate("/agent/" + id);
  };

  return (
    <div
      key={agent.id}
      className="item-agent"
      onClick={() => handleNavigate(agent.id)}
    >
      <div className="avatar-text">
        <div>
          <img
            src={agent.avatar?.length ? agent.avatar : "/avatar.jpg"}
            alt=""
          />
        </div>
        <div>
          <span>
            <img className="agent-icon" src="/icons/user1.svg" />{" "}
            <b>{agent.fullName}</b>
          </span>
          <span>
            <img className="agent-icon" src="/icons/phone.svg" />{" "}
            <b>{agent.phoneNumber}</b>
          </span>
          <span>
            <img className="agent-icon" src="/icons/email1.svg" />{" "}
            <b>{agent.email}</b>
          </span>
        </div>
      </div>
      <div className="info">
        <span>
          <img className="agent-icon" src="/icons/location.svg" />{" "}
          <b>{agent.address}</b>
        </span>
        <span className="rev-ads">
          <span className="stars">
            Review:
            {[1, 2, 3, 4, 5].map((item) => {
              if (item <= agent.review) {
                return (
                  <img key={item} className="star-icon" src="/icons/star.svg" />
                );
              } else {
                return (
                  <img
                    key={item}
                    className="star-icon"
                    src="/icons/star1.svg"
                  />
                );
              }
            })}{" "}
          </span>
          <span>
            Ads: <b>{agent.adsCount}</b>
          </span>
        </span>
      </div>

      <div className="footer-agent">
        <span className="agent-btns">
          <a href="#">
            <InstagramIcon width={25} fill="#111" />
          </a>
          <a href="#">
            <TelegramIcon width={25} fill="#111" />
          </a>
          <a href="#">
            <WebIcon width={33} height={33} fill="#111" />
          </a>
        </span>
      </div>
    </div>
  );
};

export default AgentCard;
