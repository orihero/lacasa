import { useCallback, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { ArrowDownUp, SearchX } from "lucide-react";
import { apiClient } from "../../lib/apiClient";
import { toValidDate } from "@lacasa/domain";
import ListingCard from "../components/ListingCard";
import MarketMap from "../components/MarketMap";

const SORTS = [
  { key: "newest", label: "Newest" },
  { key: "lowestPrice", label: "Price ↑" },
  { key: "highestPrice", label: "Price ↓" },
];

const FILTER_KEYS = [
  "district",
  "category",
  "type",
  "rooms",
  "repairment",
  "furniture",
  "priceMin",
  "priceMax",
  "areaMin",
  "areaMax",
];

function fromParams(searchParams) {
  const filters = {};
  for (const key of FILTER_KEYS) {
    const value = searchParams.get(key);
    if (value) filters[key] = value;
  }
  return filters;
}

// Search (mockup #/u-search): filter rail, 2-up results, sticky map with
// price pins. Filters run server-side through GET /ads (the api-client's
// AdFilters); sorting is client-side since the public endpoint has no sort
// param. The URL is the state — Apply writes searchParams, searchParams
// drive the fetch, so results are shareable links.
function SearchPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const applied = useMemo(() => fromParams(searchParams), [searchParams]);
  const [draft, setDraft] = useState(applied);
  const [ads, setAds] = useState(null);
  const [sort, setSort] = useState("newest");

  useEffect(() => {
    setDraft(applied);
    setAds(null);
    apiClient.ads
      .list(applied)
      .then(setAds)
      .catch((error) => {
        console.error(error);
        setAds([]);
      });
  }, [applied]);

  const apply = useCallback(
    (next) => {
      const params = new URLSearchParams();
      for (const key of FILTER_KEYS) {
        if (next[key]) params.set(key, next[key]);
      }
      setSearchParams(params);
    },
    [setSearchParams],
  );

  const sorted = useMemo(() => {
    if (!ads) return null;
    const list = [...ads];
    if (sort === "lowestPrice") list.sort((a, b) => a.price - b.price);
    else if (sort === "highestPrice") list.sort((a, b) => b.price - a.price);
    else
      list.sort(
        (a, b) =>
          (toValidDate(b.createdAt)?.getTime() ?? 0) -
          (toValidDate(a.createdAt)?.getTime() ?? 0),
      );
    return list;
  }, [ads, sort]);

  const setChip = (key, value) =>
    setDraft((d) => ({ ...d, [key]: d[key] === value ? "" : value }));

  const chipCls = (on) => `chip${on ? " is-on" : ""}`;

  return (
    <div className="wrap results">
      <aside className="rail">
        <h4>Deal type</h4>
        <div className="chips">
          <button className={chipCls(draft.category === "sale")} onClick={() => setChip("category", "sale")}>
            Sale
          </button>
          <button className={chipCls(draft.category === "rent")} onClick={() => setChip("category", "rent")}>
            Rent
          </button>
        </div>
        <h4>Price range</h4>
        <div className="two">
          <input
            className="field num"
            type="number"
            min="0"
            placeholder="Min"
            value={draft.priceMin ?? ""}
            onChange={(e) => setDraft({ ...draft, priceMin: e.target.value })}
          />
          <input
            className="field num"
            type="number"
            min="0"
            placeholder="Max"
            value={draft.priceMax ?? ""}
            onChange={(e) => setDraft({ ...draft, priceMax: e.target.value })}
          />
        </div>
        <h4>Rooms</h4>
        <div className="chips">
          {["1", "2", "3", "4", "5"].map((n) => (
            <button key={n} className={chipCls(draft.rooms === n)} onClick={() => setChip("rooms", n)}>
              {n}
            </button>
          ))}
        </div>
        <h4>Property type</h4>
        <select
          className="field"
          value={draft.type ?? ""}
          onChange={(e) => setDraft({ ...draft, type: e.target.value })}
        >
          <option value="">Any type</option>
          <option value="residential">Residential</option>
          <option value="nonresidential">Commercial</option>
        </select>
        <select
          className="field"
          value={draft.repairment ?? ""}
          onChange={(e) => setDraft({ ...draft, repairment: e.target.value })}
        >
          <option value="">Any repairment</option>
          <option value="notRepaired">No repair</option>
          <option value="normal">Normal</option>
          <option value="good">Good</option>
          <option value="excellent">Excellent</option>
        </select>
        <h4>District</h4>
        <input
          className="field"
          placeholder="Any district"
          value={draft.district ?? ""}
          onChange={(e) => setDraft({ ...draft, district: e.target.value })}
        />
        <h4>Area, m²</h4>
        <div className="two">
          <input
            className="field num"
            type="number"
            min="0"
            placeholder="From"
            value={draft.areaMin ?? ""}
            onChange={(e) => setDraft({ ...draft, areaMin: e.target.value })}
          />
          <input
            className="field num"
            type="number"
            min="0"
            placeholder="To"
            value={draft.areaMax ?? ""}
            onChange={(e) => setDraft({ ...draft, areaMax: e.target.value })}
          />
        </div>
        <h4>Furniture</h4>
        <div className="chips">
          <button className={chipCls(!draft.furniture)} onClick={() => setDraft({ ...draft, furniture: "" })}>
            Any
          </button>
          <button
            className={chipCls(draft.furniture === "withFurniture")}
            onClick={() => setChip("furniture", "withFurniture")}
          >
            Furnished
          </button>
        </div>
        <div style={{ display: "flex", gap: 8, marginTop: 20 }}>
          <button className="btn btn--p" style={{ flex: 1 }} onClick={() => apply(draft)}>
            Apply filters
          </button>
          <button className="btn btn--g" onClick={() => apply({})}>
            Reset
          </button>
        </div>
      </aside>

      <main>
        <div className="toolrow">
          <div>
            <h2 className="h2">
              {sorted === null
                ? "Searching…"
                : `${sorted.length} listing${sorted.length === 1 ? "" : "s"} in Tashkent`}
            </h2>
            <p className="sub">Sorted by {SORTS.find((s) => s.key === sort).label.toLowerCase()}</p>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            {SORTS.map((s) => (
              <button
                key={s.key}
                className={chipCls(sort === s.key)}
                onClick={() => setSort(s.key)}
              >
                {s.key === "newest" && <ArrowDownUp size={14} />} {s.label}
              </button>
            ))}
          </div>
        </div>
        <div className="grid grid--2">
          {sorted === null
            ? Array.from({ length: 4 }, (_, i) => <div key={i} className="skeleton" />)
            : sorted.map((ad) => <ListingCard key={ad.id} ad={ad} />)}
        </div>
        {sorted !== null && sorted.length === 0 && (
          <div className="empty">
            <SearchX size={38} />
            <b>Nothing matches these filters</b>
            <p>Try widening the price range or clearing a filter or two.</p>
          </div>
        )}
      </main>

      <aside className="mapbox">
        <MarketMap ads={sorted ?? []} />
      </aside>
    </div>
  );
}

export default SearchPage;
