import React from "react";
import { Triangle } from "react-loader-spinner";
import HorizontalCard from "../../components/h-card/HCard";
import { useListStore } from "../../lib/adsListStore";
import "./horizontalList.scss";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";

export default function HorizontalList() {
  const { list, isLoading } = useListStore();
  const { t } = useTranslation();

  const navigate = useNavigate();

  const handleNavigationList = () => {
    navigate("/list");
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
      <div className="hList">
        {list.map((item) => {
          return <HorizontalCard data={item} />;
        })}
      </div>
      <button onClick={handleNavigationList} className="btn-more">
        {t("view_more")}
      </button>
    </>
  );
}
