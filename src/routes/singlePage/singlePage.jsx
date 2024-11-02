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
import InfoIcon from "../../components/icons/InfoIcon";
import FloorIcon from "../../components/icons/FloorIcon";

function SinglePage() {
  const { id } = useParams();
  const { adsData, isLoading, fetchAdsById } = useListStore();
  const { fetchUserById, agent, currentUser } = useUserStore();
  useEffect(() => {
    if (id) {
      fetchAdsById(id);
    }
  }, [id]);

  useEffect(() => {
    if (adsData?.id) {
      console.log(adsData);
      fetchUserById(adsData.agentId);
    }
  }, [adsData?.id]);

  console.log(adsData);

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
          <p className="title">Дополнительная информация</p>
          <div className="listVertical">
            {adsData?.optionList?.map((option) => {
              return (
                <div key={option?.id?.toString()} className="feature">
                  <InfoIcon width={18} />
                  <div className="featureText">
                    <span>{option?.key}</span>
                    <p>{option?.value}</p>
                  </div>
                </div>
              );
            })}
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
            <div className="size">
              <FloorIcon color={"#888"} />
              <span>
                {adsData.storey}/{adsData.storeys}
              </span>
            </div>
          </div>
          <p className="title">Nearby Places</p>
          <div className="listHorizontal">
            {adsData?.nearPlacesList?.length &&
              (adsData?.nearPlacesList ?? [])?.map((item) => {
                return (
                  <div className="feature">
                    <span>{item}</span>
                  </div>
                );
              })}
            {/* <div className="feature">
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
            </div> */}
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
            {currentUser?.role != "agent" && (
              <button>
                <img src="/save.png" alt="" />
                Save the Place
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default SinglePage;
