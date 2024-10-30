import React from "react";
import { Triangle } from "react-loader-spinner";
import HorizontalCard from "../../components/h-card/HCard";
import { useListStore } from "../../lib/adsListStore";
import "./horizontalList.scss";

export default function HorizontalList() {
  const { list, isLoading } = useListStore();
  console.log("HorizontalList", list);

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
    <div className="hList">
      {list.map((item) => {
        return <HorizontalCard data={item} />;
      })}
    </div>
  );
}
