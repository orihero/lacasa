import type { InstagramAccount } from "@lacasa/api-client";
import "./IgProfileCard.scss";


export interface IgProfileCardProps {
  data: InstagramAccount;
}

function IgProfileCard({ data }: IgProfileCardProps) {
  return (
    <div className="ig-container">
      <img src={data.profile_picture_url} className="ig-avatar" />
      <div className="ig-info">
        <div className="ig-username">
          <img
            className="igLogo"
            src="https://static.cdnlogo.com/logos/i/93/instagram.svg"
            alt=""
          />
          <p>{data.username}</p>
        </div>
        <div className="followers">
          <p>
            <b>{data.media_count}</b>Posts
          </p>
          <p>
            <b>{data.followers_count}</b>Followers
          </p>
          <p>
            <b>{data.follows_count}</b>Following
          </p>
        </div>
      </div>
    </div>
  );
}

export default IgProfileCard;
