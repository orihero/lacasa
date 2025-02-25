import { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { Triangle } from "react-loader-spinner";
import { useNavigate, useParams } from "react-router-dom";
import FloorIcon from "../../components/icons/FloorIcon";
import InfoIcon from "../../components/icons/InfoIcon";
import RoomsIcon from "../../components/icons/RoomsIcon";
import Map from "../../components/map/Map";
import Slider from "../../components/slider/Slider";
import { useListStore } from "../../lib/adsListStore";
import { singlePostData } from "../../lib/dummydata";
import { useUserStore } from "../../lib/userStore";
import "./singlePage.scss";

function SinglePage() {
  const { id } = useParams();
  const { adsData, isLoading, fetchAdsById } = useListStore();
  const { fetchUserById, agent, currentUser } = useUserStore();
  const { t } = useTranslation();
  const navigate = useNavigate();

  useEffect(() => {
    if (id) {
      fetchAdsById(id);
    }
  }, [id]);

  useEffect(() => {
    if (adsData?.id) {
      fetchUserById(adsData.agentId);
    }
  }, [adsData?.id]);

  const handleNavigateAgent = () => {
    navigate("/agent/" + adsData.agentId);
  };

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
          <Slider
            tour3dLink={adsData?.tour3dLink}
            images={adsData?.photos ?? []}
          />
          <div className="info">
            <div className="top">
              <div className="post">
                <h1>{adsData.title}</h1>
                <div className="address">
                  <img src="/pin.png" alt="" />
                  <span>
                    {adsData.city}, {adsData.district}
                  </span>
                </div>
                <div className="price"> {adsData.price} y.e </div>
              </div>
              <div onClick={handleNavigateAgent} className="user">
                <img src={agent.avatar ?? "/avatar.jpg"} alt="" />
                <span>{agent.fullName}</span>
              </div>
            </div>
            <div className="ads-info-list">
              <span className="ads-info-item">
                {t("type")}: {t(adsData.type)}
              </span>
              <span className="ads-info-item">
                {t("category")}: {t(adsData.category)}
              </span>
              <span className="ads-info-item">
                {t("repair")}: {t(adsData.repairment)}
              </span>
              <span className="ads-info-item">
                {t("furniture")}: {t(adsData.furniture)}
              </span>
            </div>
            <div className="bottom">
              <span>{t("classification")}:</span>
              <p>{adsData.description}</p>
            </div>
          </div>
        </div>
      </div>
      <div className="features">
        <div className="wrapper">
          <p className="title">{t("additionalInfo")}</p>
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
          <p className="title">{t("sizes")}</p>
          <div className="sizes">
            <div className="size">
              <img src="/size.png" alt="" />
              <span>
                {adsData.area} m <sup>2</sup>
              </span>
            </div>
            <div className="size">
              <RoomsIcon color={"#888"} />
              <span>
                {adsData.rooms} {t("room")}
              </span>
            </div>
            <div className="size">
              <FloorIcon color={"#888"} />
              <span>
                {adsData.storey}/{adsData.floors}
              </span>
            </div>
          </div>
          <p className="title">{t("nearbyPlaces")}</p>
          <div className="listHorizontal">
            {adsData?.nearPlacesList?.length &&
              (adsData?.nearPlacesList ?? [])?.map((item) => {
                return (
                  <div key={item} className="feature">
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
          <p className="title">{t("location")}</p>
          <div className="mapContainer">
            <Map items={[singlePostData]} />
          </div>
          <div className="buttons">
            <div className="footer-btn-actions">
              <button className="apply-btn-ads-card">{t("apply")}</button>
            </div>
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
