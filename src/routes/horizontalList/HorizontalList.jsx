import React, { useEffect, useState } from "react";
import HorizontalCard from "../../components/h-card/HCard";
import "./horizontalList.scss";

export default function HorizontalList() {
  const [ads, setAds] = useState([]);

  useEffect(() => {
    return () => {};
  }, []);

  return (
    <div>
      <div className="hList">
        <HorizontalCard />
        <HorizontalCard />
        <HorizontalCard />
        <HorizontalCard />
        <HorizontalCard />
        <HorizontalCard />
        <HorizontalCard />
        <HorizontalCard />
        <HorizontalCard />
      </div>
    </div>
  );
}
