import "./singlePage.scss";
import Slider from "../../components/slider/Slider";
import Map from "../../components/map/Map";
import { singlePostData, userData } from "../../lib/dummydata";
import { useEffect } from "react";
import { useListStore } from "../../lib/adsListStore";
import { useParams } from "react-router-dom";
import { Triangle } from "react-loader-spinner";
import { useAgentsStore } from "../../lib/agentsStore";
import { useUserStore } from "../../lib/userStore";
import RoomsIcon from "../../components/icons/RoomsIcon";

function SinglePage() {
  const { id } = useParams();
  const { adsData, isLoading, fetchAdsById } = useListStore();
  const { fetchUserById, agent } = useUserStore();
  useEffect(() => {
    if (id) {
      fetchAdsById(id);
    }
  }, [id]);

  useEffect(() => {
    if (adsData?.id) {
      console.log(adsData);
      fetchUserById(adsData.agent_id);
    }
  }, [adsData?.id]);

  console.log(agent);

  if (isLoading) {
    return (
      <div className="loading">
        <Triangle
          visible={true}
          height="80"
          width="80"
          color="#4fa94d"
          ariaLabel="triangle-loading"
          wrapperStyle={{}}
          wrapperClass=""
        />
      </div>
    );
  }

  return (
    <div className="singlePage">
      <div className="details">
        <div className="wrapper">
          <Slider images={adsData?.photos ?? []} />
          <div className="info">
            <div className="top">
              <div className="post">
                <h1>{adsData.title}</h1>
                <div className="address">
                  <img src="/pin.png" alt="" />
                  <span>{adsData.address}</span>
                </div>
                <div className="price">$ {adsData.price}</div>
              </div>
              <div className="user">
                <img src={agent.avatar ?? "/avatar.jpg"} alt="" />
                <span>{agent.fullName}</span>
              </div>
            </div>
            <div className="bottom">
              <span>Tasnif:</span>
              <p>{adsData.description}</p>
            </div>
          </div>
        </div>
      </div>
      <div className="features">
        <div className="wrapper">
          <p className="title">General</p>
          <div className="listVertical">
            <div className="feature">
              <img src="/utility.png" alt="" />
              <div className="featureText">
                <span>Utilities</span>
                <p>Renter is responsible</p>
              </div>
            </div>
            <div className="feature">
              <img src="/pet.png" alt="" />
              <div className="featureText">
                <span>Pet Policy</span>
                <p>Pets Allowed</p>
              </div>
            </div>
            <div className="feature">
              <img src="/fee.png" alt="" />
              <div className="featureText">
                <span>Property Fees</span>
                <p>Must have 3x the rent in total household income</p>
              </div>
            </div>
          </div>
          <p className="title">Sizes</p>
          <div className="sizes">
            <div className="size">
              <img src="/size.png" alt="" />
              <span>
                {adsData.area} m <sup>2</sup>
              </span>
            </div>
            <div className="size">
              <RoomsIcon color={"#888"} />
              <span>{adsData.rooms} rooms</span>
            </div>
            {/* <div className="size">
              <img src="/bath.png" alt="" />
              <span>1 bathroom</span>
            </div> */}
          </div>
          <p className="title">Nearby Places</p>
          <div className="listHorizontal">
            <div className="feature">
              <img src="/school.png" alt="" />
              <div className="featureText">
                <span>School</span>
                <p>250m away</p>
              </div>
            </div>
            <div className="feature">
              <img src="/pet.png" alt="" />
              <div className="featureText">
                <span>Bus Stop</span>
                <p>100m away</p>
              </div>
            </div>
            <div className="feature">
              <img src="/fee.png" alt="" />
              <div className="featureText">
                <span>Restaurant</span>
                <p>200m away</p>
              </div>
            </div>
          </div>
          <p className="title">Location</p>
          <div className="mapContainer">
            <Map items={[singlePostData]} />
          </div>
          <div className="buttons">
            <button>
              <img src="/chat.png" alt="" />
              Send a Message
            </button>
            <button>
              <img src="/save.png" alt="" />
              Save the Place
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SinglePage;
