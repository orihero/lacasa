import { ITGAccount } from "../../services/tg";
import "./TgProfileCard.scss";

import React from "react";

export interface TgProfileCardProps {
  data: ITGAccount;
}

function TgProfileCard({ data }: TgProfileCardProps) {
  return (
    <div className="container">
      <img src={data.file_path} className="avatar" />
      <div className="info">
        <div className="username">
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
