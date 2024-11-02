import { Link } from "react-router-dom";
import "./card.scss";
import RoomsIcon from "../icons/RoomsIcon";

function Card({ item }) {
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
          <span>{item.address}</span>
        </p>
        <p className="price">$ {item.price}</p>
        <div className="bottom">
          <div className="features">
            <div className="feature">
              <RoomsIcon color={"#888"} />
              <span>{item.rooms} rooms</span>
            </div>
            <div className="feature">
              <img src="/size.png" alt="" />
              <p>
                {item.area.length > 0 ? item.area : "-"} m<sup>2</sup>
              </p>
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
