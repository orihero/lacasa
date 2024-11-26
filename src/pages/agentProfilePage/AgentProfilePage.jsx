import { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { Triangle } from "react-loader-spinner";
import { useParams } from "react-router-dom";
import List from "../../components/list/List";
import { useListStore } from "../../lib/adsListStore";
import { useUserStore } from "../../lib/userStore";
import "./agentProfile.scss";
import InstagramIcon from "../../components/icons/InstagramIcon";
import TelegramIcon from "../../components/icons/TelegramIcon";
import WebIcon from "../../components/icons/WebIcon";

function AgentProfilePage() {
  const { agent, fetchUserById } = useUserStore();
  const { fetchAdsByAgentId, isLoading, myList } = useListStore();
  const { id } = useParams();
  const { t } = useTranslation();

  useEffect(() => {
    if (id) {
      fetchUserById(id);
      fetchAdsByAgentId(id);
    }
  }, [id]);

  return (
    <div className="agentProfilePage">
      <div className="details">
        <div className="wrapper">
          <div className="title">
            <h1>{t("agentInformation")}</h1>
            {/* <div className="title-btn">
              <Link to={"/updateProfile"}>
                <button>Update Profile</button>
              </Link>
              <button onClick={handleLogout}>Logout</button>
            </div> */}
          </div>
          <div className="info">
            <div>
              <span>
                {t("fullName")}:<b>{agent?.fullName}</b>
              </span>
              <span>
                {t("email")}: <b>{agent?.email}</b>
              </span>
              <span>
                {t("phone")}: <b>{agent?.phoneNumber}</b>
              </span>
              <div className="footer-agent">
                <span className="agent-btns">
                  <a href="#">
                    <InstagramIcon width={25} fill="#111" />
                  </a>
                  <a href="#">
                    <TelegramIcon width={25} fill="#111" />
                  </a>
                  <a href="#">
                    <WebIcon width={33} height={33} fill="#111" />
                  </a>
                </span>
              </div>
            </div>
            <div>
              <span>
                <img src={agent?.avatar || "/avatar.jpg"} alt="" />
              </span>
            </div>
          </div>
          {!isLoading ? (
            <>
              <div className="title">
                <h1>{t("adsList")}</h1>
              </div>
              <List data={myList} />
            </>
          ) : (
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
          )}
        </div>
      </div>
      <div className="chatContainer">
        <div className="wrapper">{/* <Chat /> */}</div>
      </div>
    </div>
  );
}

export default AgentProfilePage;
