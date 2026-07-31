import { ITGAccount } from "../../services/tg";
import "./tgProfileCard.scss";

import React from "react";

export interface TgProfileCardProps {
  data: ITGAccount;
}

function TgProfileCard({ data }: TgProfileCardProps) {
  return (
    <div className="tg-container">
      <img src={data.file_path} className="tg-avatar" />
      <div className="tg-info">
        <div className="tg-username">
          <img
            className="igLogo"
            src="https://www.cdnlogo.com/logos/t/39/telegram.svg"
            alt=""
          />
          <p>{data.username}</p>
        </div>
        <h4>{data.title}</h4>
        <div className="followers">
          <p>
            <b>{data.members_count}</b>Members
          </p>
        </div>
      </div>
    </div>
  );
}

export default TgProfileCard;
