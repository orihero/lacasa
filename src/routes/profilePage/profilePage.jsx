import { signOut } from "firebase/auth";
import { ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { Triangle } from "react-loader-spinner";
import { Link, Outlet, useNavigate } from "react-router-dom";
import Filter from "../../components/filter/Filter";
import List from "../../components/list/List";
import Sidebar from "../../components/sidebar/Sidebar";
import { useListStore } from "../../lib/adsListStore";
import { auth } from "../../lib/firebase";
import { useUserStore } from "../../lib/userStore";
import "./profilePage.scss";

function ProfilePage() {
  const { currentUser, logout, isLoading } = useUserStore();
  const { fetchAdsByAgentId, myList } = useListStore();
  const navigate = useNavigate();

  const [isFilter, setFilter] = useState(false);
  const { t } = useTranslation();

  useEffect(() => {
    if (currentUser?.id && currentUser?.role === "agent") {
      fetchAdsByAgentId(currentUser.id);
    }
    if (currentUser?.role === "coworker") {
      fetchAdsByAgentId(currentUser.agentId);
      handleNavigateProfileS();
    }
  }, [currentUser?.id]);

  const handleLogout = async () => {
    await signOut(auth);
    logout();
    navigate("/");
  };

  const handleNavigateProfileS = () => {
    navigate("/profile/" + currentUser?.id + "/setting");
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
    <>
      {currentUser?.role !== "user" ? (
        <div className="agent-content">
          <Sidebar currentUser={currentUser} handleLogout={handleLogout} />
          <div className="content-list">
            <Outlet />
          </div>
        </div>
      ) : (
        <div className="profilePage">
          <div className="details">
            <div className="wrapper">
              <div className="title">
                <h1>{t("userInformation")}</h1>
                <div className="title-btn">
                  <Link to={"/updateProfile"}>
                    <button>{t("updateProfile")}</button>
                  </Link>
                  <button onClick={handleLogout}>{t("logout")}</button>
                </div>
              </div>
              <div className="info">
                <div>
                  <span>
                    {t("fullName")}: <b>{currentUser?.fullName}</b>
                  </span>
                  <span>
                    {t("email")}: <b>{currentUser?.email}</b>
                  </span>
                  <span>
                    {t("phone")}: <b>{currentUser?.phoneNumber}</b>
                  </span>
                </div>
                <div>
                  <span>
                    <img src={currentUser?.avatar || "/avatar.jpg"} alt="" />
                  </span>
                </div>
              </div>
              <div className="profile-user-agent">
                <button className="profile-user-agent-btn">
                  <a target="_blank" href="https://forms.gle/1Kr71PzWjqqCQcVTA">
                    Agent sifatida ro'yxatdan o'tish
                  </a>{" "}
                  <ExternalLink />
                </button>
              </div>
              {currentUser?.role === "agent" ? (
                <>
                  <div className="title">
                    <h1>{t("myList")}</h1>
                    <div style={{ display: "flex", gap: "10px" }}>
                      <button onClick={() => setFilter((prev) => !prev)}>
                        {t("filter")}
                      </button>
                      <Link to={"/post"}>
                        <button> {t("createNewPost")}</button>
                      </Link>
                    </div>
                  </div>
                  {isFilter && (
                    <div className="filter-tools">
                      <Filter />
                    </div>
                  )}
                  <List data={myList} isLoading={isLoading} />
                </>
              ) : (
                <>
                  {!isLoading ? (
                    <>
                      <div className="title">
                        <h1>{t("savedList")}</h1>
                      </div>
                      <List />
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
                </>
              )}
            </div>
          </div>
          <div className="chatContainer">
            <div className="wrapper">{/* <Chat /> */}</div>
          </div>
        </div>
      )}
    </>
  );
}

export default ProfilePage;
