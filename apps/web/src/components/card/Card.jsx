import { Link } from "react-router-dom";
import "./card.scss";
import RoomsIcon from "../icons/RoomsIcon";
import FloorIcon from "../icons/FloorIcon";
import { useTranslation } from "react-i18next";

function Card({ item }) {
  const { t } = useTranslation();

  return (
    <div key={item.id} className="card">
      <Link to={`/post/${item.id}`} className="imageContainer">
        <img src={item.photos[0]} alt="" />
      </Link>
      <div className="textContainer">
        <h2 className="title">
          <Link to={`/post/${item.id}`}>{item.title}</Link>
        </h2>
        <p className="address">
          <img src="/pin.png" alt="" />
          <span>
            {" "}
            {item.city}, {item.district}
          </span>
        </p>
        <p className="price">$ {item.price}</p>
        <div className="bottom">
          <div className="features">
            <div className="feature">
              <RoomsIcon color={"#888"} />
              <span>
                {item.rooms} {t("room")}
              </span>
            </div>
            <div className="feature">
              <img src="/size.png" alt="" />
              <p>
                {item.area} m<sup>2</sup>
              </p>
            </div>
            <div className="feature">
              <FloorIcon color={"#888"} />
              <span>
                {item.storey}/{item.floors}
              </span>
            </div>
          </div>
          <div className="icons">
            {/* <div className="icon">
              <img src="/save.png" alt="" />
            </div> */}
            <div className="icon">
              <img src="/chat.png" alt="" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Card;
