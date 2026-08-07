import { ITGAccount } from "../../services/tg";
import "./tgProfileCard.scss";


export interface TgProfileCardProps {
  data: ITGAccount;
}

// `data` now only ever carries `id` — see services/tg.ts's file header for
// why the old title/username/avatar/member-count enrichment was removed
// (it required the browser-side bot token, and the server has no
// enrichment endpoint to replace it with). Every other field is rendered
// as an honest "unavailable" placeholder rather than fabricated.
function TgProfileCard({ data }: TgProfileCardProps) {
  return (
    <div className="tg-container">
      {data.file_path ? (
        <img src={data.file_path} className="tg-avatar" />
      ) : (
        <div className="tg-avatar tg-avatar-placeholder" aria-hidden="true" />
      )}
      <div className="tg-info">
        <div className="tg-username">
          <img
            className="igLogo"
            src="https://www.cdnlogo.com/logos/t/39/telegram.svg"
            alt=""
          />
          <p>{data.username ? `@${data.username}` : `Chat ${data.id ?? "?"}`}</p>
        </div>
        <h4>{data.title ?? "Telegram channel"}</h4>
        <div className="followers">
          {data.members_count != null ? (
            <p>
              <b>{data.members_count}</b>Members
            </p>
          ) : (
            <p className="tg-unavailable">Channel details unavailable</p>
          )}
        </div>
      </div>
    </div>
  );
}

export default TgProfileCard;
