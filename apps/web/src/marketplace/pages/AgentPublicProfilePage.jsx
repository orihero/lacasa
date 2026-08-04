import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, Phone, UserRound, Users } from "lucide-react";
import { apiClient } from "../../lib/apiClient";
import ListingCard from "../components/ListingCard";

// Public agent profile (mockup #/u-agent): stats card + contact, and the
// agent's active listings via the anonymous scope of GET /ads.
function AgentPublicProfilePage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [agent, setAgent] = useState(null);
  const [ads, setAds] = useState(null);
  const [missing, setMissing] = useState(false);

  useEffect(() => {
    setAgent(null);
    setAds(null);
    setMissing(false);
    apiClient.agents
      .getById(id)
      .then(setAgent)
      .catch((error) => {
        console.error(error);
        setMissing(true);
      });
    apiClient.ads
      .getAds({ scope: "public", agentId: id })
      .then(setAds)
      .catch((error) => {
        console.error(error);
        setAds([]);
      });
  }, [id]);

  if (missing) {
    return (
      <div className="wrap">
        <div className="empty">
          <Users size={38} />
          <b>Agent not found</b>
          <p>This profile may have been removed.</p>
          <button className="btn btn--dark" style={{ marginTop: 16 }} onClick={() => navigate("/agents")}>
            Browse all agents
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="wrap pad">
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 20 }}>
        <button className="iconbtn" onClick={() => navigate(-1)} aria-label="Back">
          <ArrowLeft size={17} />
        </button>
        <span className="sub">Agents / {agent?.fullName ?? "…"}</span>
      </div>
      <div className="profilegrid">
        <div className="pricebox" style={{ textAlign: "center" }}>
          <div
            className="agentcard__av"
            style={{
              width: 96,
              height: 96,
              ...(agent?.avatar ? { backgroundImage: `url(${agent.avatar})` } : {}),
            }}
          >
            {!agent?.avatar && <UserRound size={36} />}
          </div>
          <div className="h2" style={{ marginTop: 14 }}>
            {agent?.fullName ?? "…"}
          </div>
          <p className="sub">Agent · Tashkent</p>
          {agent && (
            <div className="agentcard__s" style={{ marginTop: 18 }}>
              <div>
                <b className="num">{agent.adsCount}</b>
                <span>Listings</span>
              </div>
              <div>
                <b className="num">{agent.dealsClosedCount}</b>
                <span>Closed</span>
              </div>
            </div>
          )}
          {agent?.phoneNumber && (
            <div className="stack" style={{ marginTop: 18 }}>
              <a className="btn btn--p" href={`tel:${agent.phoneNumber}`}>
                <Phone size={15} /> {agent.phoneNumber}
              </a>
            </div>
          )}
        </div>
        <div>
          <div className="rowhead">
            <div>
              <h2 className="h2">Active listings</h2>
              <p className="sub">
                {ads === null ? "Loading…" : `${ads.length} currently on the market`}
              </p>
            </div>
          </div>
          <div className="grid grid--2">
            {ads === null
              ? Array.from({ length: 2 }, (_, i) => <div key={i} className="skeleton" />)
              : ads.map((ad) => <ListingCard key={ad.id} ad={ad} compact />)}
          </div>
          {ads !== null && ads.length === 0 && (
            <div className="empty">
              <b>No active listings right now</b>
              <p>Check back soon — this agent publishes regularly.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default AgentPublicProfilePage;
