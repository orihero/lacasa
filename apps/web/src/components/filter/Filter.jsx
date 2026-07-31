import "./filter.scss";
import regionData from "../../regions.json";
import { useState } from "react";
import { useListStore } from "../../lib/adsListStore";
import { useUserStore } from "../../lib/userStore";
import { debounce } from "lodash";
import { useTranslation } from "react-i18next";

const priceList = [
  100000, 500000, 1000000, 5000000, 10000000, 30000000, 50000000, 100000000,
  500000000,
];

function Filter() {
  const { t } = useTranslation();
  const { fetchAdsByAgentId } = useListStore();
  const { currentUser } = useUserStore();
  const [regionId, setRegionId] = useState(0);
  const agentId =
    currentUser.role === "agent" ? currentUser.id : currentUser.agentId;
  const [filters, setFilters] = useState({
    city: "",
    district: "",
    category: "",
    type: "",
    rooms: "",
    areaMin: "",
    areaMax: "",
    priceMin: "",
    priceMax: "",
    repairment: "",
    furniture: "",
    storey: "",
  });

  console.log(filters);

  const debouncedFetchAds = debounce((updatedFilters) => {
    fetchAdsByAgentId(agentId ?? currentUser.id, updatedFilters);
  }, 300);

  const handleFilterChange = (field, value) => {
    const updatedFilters = { ...filters, [field]: value };
    setFilters(updatedFilters);
    debouncedFetchAds(updatedFilters);
  };

  return (
    <div className="filter">
      {/* <h1>
        Search results for <b>London</b>
      </h1> */}
      <div className="top">
        <div className="item">
          <label htmlFor="city">{t("city")}</label>
          <select
            name="city"
            id="city"
            onChange={(e) => {
              setRegionId(
                regionData.regions.find((r) => r.name === e.target.value)?.id ||
                  0,
              );
              handleFilterChange("city", e.target.value);
            }}
          >
            <option key={"0"} value="" defaultChecked></option>
            {regionData.regions.map((region) => (
              <option key={region.id.toString()} value={region.name}>
                {region.name}
              </option>
            ))}
          </select>
        </div>
        <div className="item">
          <label htmlFor="district">{t("district")}</label>
          <select
            name="district"
            id="district"
            disabled={regionId === 0}
            onChange={(e) => handleFilterChange("district", e.target.value)}
          >
            <option key={"0"} value="" defaultChecked></option>
            {regionData.districts
              .filter((item) => item.region_id === regionId)
              .map((district) => (
                <option key={district.id.toString()} value={district.name}>
                  {district.name}
                </option>
              ))}
          </select>
        </div>
        <div className="item type">
          <label htmlFor="category">{t("category")}</label>
          <select
            name="category"
            id="category"
            onChange={(e) => handleFilterChange("category", e.target.value)}
          >
            <option value=""></option>
            <option value="rent">{t("rent")}</option>
            <option value="sale">{t("sale")}</option>
          </select>
        </div>
      </div>
      <div className="bottom">
        <div className="item rooms">
          <label htmlFor="rooms">{t("room_count")}</label>
          <select
            name="rooms"
            id="rooms"
            onChange={(e) => handleFilterChange("rooms", e.target.value)}
          >
            <option value="all"></option>
            {[1, 2, 3, 4, 5, 6].map((num) => (
              <option key={num} value={num}>
                {num}
              </option>
            ))}
          </select>
        </div>
        <div className="item">
          <label htmlFor="areaMin">Min.Общая площадь</label>
          <input
            type="number"
            id="areaMin"
            name="area-min"
            placeholder="20"
            onChange={(e) =>
              handleFilterChange("areaMin", parseInt(e.target.value) || 0)
            }
          />
          <span className="area-m2">
            m <sup>2</sup>
          </span>
        </div>
        <div className="item">
          <label htmlFor="areaMax">{t("areaMax")}</label>
          <input
            type="number"
            id="areaMax"
            name="area-max"
            placeholder="40"
            onChange={(e) =>
              handleFilterChange("areaMax", parseInt(e.target.value) || 0)
            }
          />
          <span className="area-m2">
            m <sup>2</sup>
          </span>
        </div>
        <div className="item price">
          <label htmlFor="priceMin">{t("priceMin")}</label>
          <select
            name="priceMin"
            id="priceMin"
            onChange={(e) =>
              handleFilterChange("priceMin", parseInt(e.target.value) || 0)
            }
          >
            {priceList
              .filter((p) => filters.priceMax === 0 || p <= filters.priceMax)
              .map((price) => (
                <option key={price.toString()} value={price}>
                  {price}
                </option>
              ))}
          </select>
        </div>
        <div className="item price">
          <label htmlFor="priceMax">{t("priceMax")}</label>
          <select
            name="priceMax"
            id="priceMax"
            onChange={(e) =>
              handleFilterChange("priceMax", parseInt(e.target.value) || 0)
            }
          >
            {priceList
              .filter((p) => p >= filters.priceMin)
              .map((price) => (
                <option key={price.toString()} value={price}>
                  {price}
                </option>
              ))}
          </select>
        </div>
        <div className="item type">
          <label htmlFor="type">{t("type")}</label>
          <select
            onChange={(e) => handleFilterChange("type", e.target.value)}
            name="type"
          >
            <option value="" defaultChecked></option>
            <option value="residential">{t("residential")}</option>
            <option value="nonresidential">{t("nonresidential")}</option>
          </select>
        </div>
        <div className="item furniture">
          <label htmlFor="furniture">{t("furniture")}</label>
          <select
            name="furniture"
            onChange={(e) => handleFilterChange("furniture", e.target.value)}
          >
            <option value="withFurniture">{t("withFurniture")}</option>
            <option value="withoutFurniture">{t("withoutFurniture")}</option>
          </select>
        </div>
        <div className="item repairment">
          <label htmlFor="repairment">{t("repair")}</label>
          <select
            name="repairment"
            onChange={(e) => handleFilterChange("repairment", e.target.value)}
          >
            <option value="notRepaired" defaultChecked>
              {t("notRepaired")}
            </option>
            <option value="normal">{t("normal")}</option>
            <option value="good">{t("good")}</option>
            <option value="excellent">{t("excellent")}</option>
          </select>
        </div>
        <div className="item">
          <label htmlFor="storey">{t("storey")}</label>
          <input
            id="storey"
            name="storey"
            type="number"
            placeholder="5"
            onChange={(e) =>
              handleFilterChange("storey", parseInt(e.target.value) || 0)
            }
          />
        </div>
        <div className="item sort">
          <label htmlFor="sort">{t("sort")}</label>
          <select
            name="sort"
            id="sort"
            onChange={(e) =>
              fetchAdsByAgentId(currentUser.id, {}, e.target.value)
            }
          >
            <option value="highestPrice">{t("highestPrice")}</option>
            <option value="lowestPrice">{t("lowestPrice")}</option>
            <option value="newest">{t("newest")}</option>
          </select>
        </div>
      </div>
    </div>
  );
}

export default Filter;
