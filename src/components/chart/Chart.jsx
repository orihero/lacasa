import React, { useEffect, useMemo } from "react";
import "./chart.scss";
import { useTranslation } from "react-i18next";
import HeaderCard from "./components/HeaderCard";
import AdsChart from "./components/AdsChart";
import CoworkerList from "./components/CoworkerList";
import CoworkerChart from "./components/CoworkerChart";
import { useCoworkerStore } from "../../lib/useCoworkerStore";
import { useUserStore } from "../../lib/userStore";
import { useListStore } from "../../lib/adsListStore";
import { useStatisticsStore } from "../../lib/useStatisticsStore";

const Chart = () => {
  const { t } = useTranslation();
  const { fetchCoworkerList, list } = useCoworkerStore();
  const { currentUser } = useUserStore();
  const { fetchAdsByStage } = useListStore();
  const {
    getAdsStatistics,
    adsNewCount,
    adsSoldCount,
    getCoworkerStatistics,
    listCwrkST,
  } = useStatisticsStore();

  useEffect(() => {
    if (currentUser?.id && currentUser.role == "agent") {
      fetchCoworkerList(currentUser?.id);
      fetchAdsByStage(currentUser?.id);
      getAdsStatistics(currentUser?.id);
      getCoworkerStatistics(currentUser?.id);
    }
  }, [currentUser?.id]);

  const generateCoworkerStatistics = useMemo(() => {
    if (currentUser?.id && listCwrkST.length && list?.length) {
      const coworkerStats = list?.map((coworker) => {
        const coworkerAdsCreate = listCwrkST.filter(
          (item) => item.coworkerId === coworker.id && item?.stage == 1,
        );
        const coworkerAdsSold = listCwrkST.filter(
          (item) => item.coworkerId === coworker.id && item?.stage == 2,
        );
        const coworkerLead = listCwrkST.filter(
          (item) => item.coworkerId === coworker.id && item?.stage == 4,
        );
        return {
          ...coworker,
          name: coworker.fullName,
          adsCount: coworkerAdsCreate.length,
          soldCount: coworkerAdsSold.length,
          leadCount: coworkerLead.length,
        };
      });
      return coworkerStats;
    }
  }, [currentUser?.id, listCwrkST, list]);

  return (
    <div className="chart-container">
      <div className="chart-header mt-1 mb-2 flex justify-center">
        <h2>Analytics</h2>
        <div>
          <select
            className="chart-select-time"
            onChange={(e) => getAdsStatistics(currentUser?.id, e.target.value)}
          >
            <option value="all">All</option>
            <option value="thisMonth">This month</option>
            <option value="thisWeek">This week</option>
            <option value="today">Today</option>
          </select>
        </div>
      </div>
      <div className="">
        <h1 className="text-xl">Ads statistics</h1>
        <div className="flex gap-2 mt-2 justify-between">
          <HeaderCard
            data={{ newCount: adsNewCount, soldCount: adsSoldCount }}
          />
          <AdsChart />
        </div>
      </div>
      <div className="mt-3">
        <h1 className="text-xl">Coworker statistics</h1>
        <div className="flex gap-2 mt-2 justify-between">
          <CoworkerList data={generateCoworkerStatistics ?? []} />
          <CoworkerChart data={generateCoworkerStatistics ?? []} />
        </div>
      </div>
    </div>
  );
};

export default Chart;
