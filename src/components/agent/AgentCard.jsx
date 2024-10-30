import React from "react";
import "./agentCard.scss";

const AgentCard = ({ agent }) => {
  return (
    <div key={agent.id} className="item-agent">
      <div>
        <span>
          Name: <b>{agent.name}</b>
        </span>
        <span>
          Phone: <b>{agent.phone}</b>
        </span>
        <span>
          E-mail: <b>{agent.email}</b>
        </span>
        <span>
          Telegram:{" "}
          <a href="https://t.me/@uy_bozor_joy_savdo" target="_blank">
            {agent.telegram}
          </a>
        </span>
        <span>
          Instagram:{" "}
          <a href="https://t.me/@uy_bozor_joy_savdo" target="_blank">
            {agent.instagram}
          </a>
        </span>
        <span>
          Web site:{" "}
          <a
            href="https://ismoilabdujalilov6.wixsite.com/-site-1"
            target="_blank"
          >
            {agent.website}
          </a>
        </span>
        <span>
          Address: <b>{agent.address}</b>
        </span>
        <span>
          Review:{" "}
          <span className="stars">
            {[1, 2, 3, 4, 5].map((item) => {
              if (item <= agent.review) {
                return <img className="star-icon" src="/icons/star.svg" />;
              } else {
                return <img className="star-icon" src="/icons/star1.svg" />;
              }
            })}{" "}
          </span>
          <b>{agent.review}</b>
        </span>
        <span>
          Ads: <b>{agent.ads}</b>
        </span>
      </div>
      <div className="right-agent">
        <span>
          <img
            src={agent.avatar.length ? agent.avatar : "/avatar.jpg"}
            alt=""
          />
        </span>
        <span className="agent-btns">
          <button>Contact</button>
          <button>View Listings</button>
        </span>
      </div>
    </div>
  );
};

export default AgentCard;
