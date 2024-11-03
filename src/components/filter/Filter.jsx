import "./filter.scss";
import regionData from "../../regions.json";
import { useState } from "react";
import { useListStore } from "../../lib/adsListStore";
import { useUserStore } from "../../lib/userStore";
import { debounce } from "lodash";

const priceList = [
  100000, 500000, 1000000, 5000000, 10000000, 30000000, 50000000, 100000000,
  500000000,
];

function Filter() {
  const { fetchAdsByAgentId } = useListStore();
  const { currentUser } = useUserStore();
  const [regionId, setRegionId] = useState(0);
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
    fetchAdsByAgentId(currentUser.id, updatedFilters);
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
          <label htmlFor="city">Город</label>
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
          <label htmlFor="district">Район</label>
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
          <label htmlFor="category">Категория</label>
          <select
            name="category"
            id="category"
            onChange={(e) => handleFilterChange("category", e.target.value)}
          >
            <option value=""></option>
            <option value="buy">Аренда</option>
            <option value="rent">Продажа</option>
          </select>
        </div>
        <div className="item rooms">
          <label htmlFor="rooms">Кол.комнат</label>
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
      </div>
      <div className="bottom">
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
          <label htmlFor="areaMax">Max.Общая площадь</label>
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
        <div className="item">
          <label htmlFor="priceMin">Min.Цена</label>
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
        <div className="item">
          <label htmlFor="priceMax">Max.Цена</label>
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
          <label htmlFor="type">Тип</label>
          <select
            onChange={(e) => handleFilterChange("type", e.target.value)}
            name="type"
          >
            <option value="" defaultChecked></option>
            <option value="residential">Жилое</option>
            <option value="nonresidential">Не Жилое</option>
          </select>
        </div>
        <div className="item furniture">
          <label htmlFor="furniture">Мебель</label>
          <select
            name="furniture"
            onChange={(e) => handleFilterChange("furniture", e.target.value)}
          >
            <option value="withFurniture">С мебелью</option>
            <option value="withoutFurniture">Без мебели</option>
          </select>
        </div>
        <div className="item repairment">
          <label htmlFor="repairment">Ремонт</label>
          <select
            name="repairment"
            onChange={(e) => handleFilterChange("repairment", e.target.value)}
          >
            <option value="notRepaired" defaultChecked>
              Требуется ремонт
            </option>
            <option value="normal">Нормальный</option>
            <option value="good">Хороший</option>
            <option value="excellent">Отличный</option>
          </select>
        </div>
        <div className="item">
          <label htmlFor="storey">Этаж</label>
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
          <label htmlFor="sort">Сортировка</label>
          <select
            name="sort"
            id="sort"
            onChange={(e) =>
              fetchAdsByAgentId(currentUser.id, {}, e.target.value)
            }
          >
            <option value="highestPrice">
              Цена самая низкая самая высокая
            </option>
            <option value="lowestPrice">Цена самая высокая самая низкая</option>
            <option value="newest">Новейшая</option>
          </select>
        </div>
      </div>
    </div>
  );
}

export default Filter;
