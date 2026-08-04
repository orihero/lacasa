import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  ArrowRight,
  Building2,
  House,
  LayoutGrid,
  Search,
  Sparkles,
  Store,
  Tag,
} from "lucide-react";
import { apiClient } from "../../lib/apiClient";
import { toValidDate } from "@lacasa/domain";
import ListingCard from "../components/ListingCard";
import AgentCard from "../components/AgentCard";

// Marketplace home (mockup #/u-home): hero + search bar over the newest
// listing photo, category chips, Featured Listings (4), Top Districts (4,
// derived from the live feed), Top Agents (3, by adsCount — the same measure
// the mobile home feed uses).
function MarketHome() {
  const navigate = useNavigate();
  const [ads, setAds] = useState(null);
  const [agents, setAgents] = useState([]);
  const [query, setQuery] = useState({ district: "", category: "", rooms: "", priceMax: "" });

  useEffect(() => {
    apiClient.ads
      .list()
      .then(setAds)
      .catch((error) => {
        console.error(error);
        setAds([]);
      });
    apiClient.agents
      .list()
      .then((list) => setAgents([...list].sort((a, b) => b.adsCount - a.adsCount)))
      .catch((error) => {
        console.error(error);
        setAgents([]);
      });
  }, []);

  const heroPhoto = useMemo(
    () => ads?.find((ad) => ad.photos?.length)?.photos[0],
    [ads],
  );

  const newThisWeek = useMemo(() => {
    if (!ads) return 0;
    const weekAgo = Date.now() - 7 * 24 * 3600 * 1000;
    return ads.filter((ad) => {
      const created = toValidDate(ad.createdAt);
      return created && created.getTime() >= weekAgo;
    }).length;
  }, [ads]);

  const districts = useMemo(() => {
    if (!ads) return [];
    const byDistrict = new Map();
    for (const ad of ads) {
      if (!ad.district) continue;
      const entry = byDistrict.get(ad.district) ?? { name: ad.district, count: 0, photo: null };
      entry.count += 1;
      entry.photo = entry.photo ?? ad.photos?.[0] ?? null;
      byDistrict.set(ad.district, entry);
    }
    return [...byDistrict.values()].sort((a, b) => b.count - a.count).slice(0, 4);
  }, [ads]);

  const onSearch = (event) => {
    event.preventDefault();
    const params = new URLSearchParams();
    if (query.district) params.set("district", query.district);
    if (query.category) params.set("category", query.category);
    if (query.rooms) params.set("rooms", query.rooms);
    if (query.priceMax) params.set("priceMax", query.priceMax);
    navigate(`/list?${params.toString()}`);
  };

  const chips = [
    { label: "All", icon: LayoutGrid, to: "/list" },
    { label: "Residential", icon: House, to: "/list?type=residential" },
    { label: "Commercial", icon: Store, to: "/list?type=nonresidential" },
    { label: "For rent", icon: Tag, to: "/list?category=rent" },
    { label: "For sale", icon: Building2, to: "/list?category=sale" },
  ];

  return (
    <div className="wrap">
      <div className="hero">
        <div
          className="hero__bg"
          style={heroPhoto ? { backgroundImage: `url(${heroPhoto})` } : undefined}
        />
        <div className="hero__c">
          <span className="hero__eyebrow">
            <Sparkles size={13} />
            {newThisWeek > 0
              ? `${newThisWeek} new listing${newThisWeek === 1 ? "" : "s"} in Tashkent this week`
              : "Verified listings across Tashkent"}
          </span>
          <h1>Find the place you&rsquo;ll actually want to come home to.</h1>
          <p>
            Every listing published by a verified La Casa agent — with photos, floor
            specs and a live 3D walkthrough before you ever book a viewing.
          </p>
          <form className="searchbar g" onSubmit={onSearch}>
            <div className="searchbar__f">
              <label htmlFor="mkt-q-district">Location</label>
              <input
                id="mkt-q-district"
                placeholder="Any district"
                value={query.district}
                onChange={(e) => setQuery({ ...query, district: e.target.value })}
              />
            </div>
            <div className="searchbar__f">
              <label htmlFor="mkt-q-deal">Deal</label>
              <select
                id="mkt-q-deal"
                value={query.category}
                onChange={(e) => setQuery({ ...query, category: e.target.value })}
              >
                <option value="">Any</option>
                <option value="sale">For sale</option>
                <option value="rent">For rent</option>
              </select>
            </div>
            <div className="searchbar__f">
              <label htmlFor="mkt-q-rooms">Rooms</label>
              <select
                id="mkt-q-rooms"
                value={query.rooms}
                onChange={(e) => setQuery({ ...query, rooms: e.target.value })}
              >
                <option value="">Any</option>
                {[1, 2, 3, 4, 5].map((n) => (
                  <option key={n} value={n}>
                    {n}
                  </option>
                ))}
              </select>
            </div>
            <div className="searchbar__f">
              <label htmlFor="mkt-q-price">Max price</label>
              <input
                id="mkt-q-price"
                type="number"
                min="0"
                placeholder="Any"
                value={query.priceMax}
                onChange={(e) => setQuery({ ...query, priceMax: e.target.value })}
              />
            </div>
            <button type="submit" className="btn btn--p">
              <Search size={15} /> Search
            </button>
          </form>
        </div>
      </div>

      <section className="pad">
        <div className="chips">
          {chips.map(({ label, icon: Icon, to }) => (
            <Link key={label} to={to} className="chip">
              <Icon size={15} /> {label}
            </Link>
          ))}
        </div>
      </section>

      <section style={{ paddingBottom: 44 }}>
        <div className="rowhead">
          <div>
            <h2 className="h2">Featured listings</h2>
            <p className="sub">The latest from our agents</p>
          </div>
          <Link to="/list">
            See all <ArrowRight size={13} />
          </Link>
        </div>
        <div className="grid grid--4">
          {ads === null
            ? Array.from({ length: 4 }, (_, i) => <div key={i} className="skeleton" />)
            : ads.slice(0, 4).map((ad) => <ListingCard key={ad.id} ad={ad} />)}
        </div>
        {ads !== null && ads.length === 0 && (
          <div className="empty">
            <House size={38} />
            <b>No listings yet</b>
            <p>Check back soon — agents publish new properties every day.</p>
          </div>
        )}
      </section>

      {districts.length > 0 && (
        <section style={{ paddingBottom: 44 }}>
          <div className="rowhead">
            <div>
              <h2 className="h2">Top districts</h2>
              <p className="sub">Where buyers are looking right now</p>
            </div>
          </div>
          <div className="grid grid--4">
            {districts.map((d) => (
              <button
                key={d.name}
                className="dist"
                style={d.photo ? { backgroundImage: `url(${d.photo})` } : undefined}
                onClick={() => navigate(`/list?district=${encodeURIComponent(d.name)}`)}
              >
                <div className="dist__c">
                  <b>{d.name}</b>
                  <span>
                    {d.count} listing{d.count === 1 ? "" : "s"}
                  </span>
                </div>
              </button>
            ))}
          </div>
        </section>
      )}

      {agents.length > 0 && (
        <section style={{ paddingBottom: 44 }}>
          <div className="rowhead">
            <div>
              <h2 className="h2">Top agents</h2>
              <p className="sub">Verified realtors across Tashkent</p>
            </div>
            <Link to="/agents">
              All agents <ArrowRight size={13} />
            </Link>
          </div>
          <div className="grid grid--3">
            {agents.slice(0, 3).map((agent) => (
              <AgentCard key={agent.id} agent={agent} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

export default MarketHome;
