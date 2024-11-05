import React from "react";
import "./sidebar.scss";
import { useTranslation } from "react-i18next";
import { useLocation, useNavigate } from "react-router-dom";
import UserIcon from "../icons/UserIcon";
import PhoneIcon from "../icons/PhoneIcon";
import GroupIcon from "../icons/GroupIcon";
import SettingIcon from "../icons/SettingIcon";
import ChartIcon from "../icons/ChartIcon";
import WorkIcon from "../icons/WorkIcon";
import ListIcon from "../icons/ListIcon";

const Sidebar = ({ currentUser, handleLogout }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const pathSegments = location.pathname.split("/");
  const lastSegment = pathSegments[pathSegments?.length - 1];
  return (
    <div className="sidebar">
      <div className="info">
        <div className="agent-avatar">
          <span className="user-role">{currentUser?.role}</span>
          <span>
            <img src={"" || "/avatar.jpg"} alt="" />
          </span>
        </div>
        <span>
          <i>
            <UserIcon width={15} fill={"#8d99ae"} />
          </i>
          <b>{currentUser?.fullName}</b>
        </span>
        <span>
          <PhoneIcon width={15} fill={"#8d99ae"} />{" "}
          <a href={"tel:" + currentUser?.phoneNumber}>
            <b>{currentUser?.phoneNumber}999999999</b>
          </a>
        </span>
      </div>
      <div className="menu-list">
        <span
          className={lastSegment == "profile" ? "active-menu" : ""}
          onClick={() => navigate("/profile")}
        >
          <ChartIcon width={15} />
          Statistika
        </span>
        <span
          className={lastSegment == "ads" ? "active-menu" : ""}
          onClick={() => navigate(currentUser?.id + "/ads")}
        >
          <ListIcon width={15} />
          Ads
        </span>
        <span
          className={lastSegment == "leads" ? "active-menu" : ""}
          onClick={() => navigate(currentUser?.id + "/leads")}
        >
          <GroupIcon width={15} /> Leads
        </span>
        {currentUser?.role == "agent" && (
          <span
            className={lastSegment == "coworkers" ? "active-menu" : ""}
            onClick={() => navigate(currentUser?.id + "/coworkers")}
          >
            <WorkIcon width={15} />
            Coworkers
          </span>
        )}
        <span
          className={lastSegment == "setting" ? "active-menu" : ""}
          onClick={() => navigate(currentUser?.id + "/setting")}
        >
          <SettingIcon width={15} />
          Profile Setting
        </span>
      </div>
      <span className="logout">
        <button onClick={handleLogout}>{t("logout")}</button>
      </span>
    </div>
  );
};

export default Sidebar;
