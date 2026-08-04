import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  ArrowLeft,
  BedDouble,
  Building2,
  Hammer,
  Heart,
  House,
  MapPin,
  Phone,
  Ruler,
  UserRound,
  X,
} from "lucide-react";
import { apiClient } from "../../lib/apiClient";
import { computePricePerSqm, formatCreatedAt } from "@lacasa/domain";
import { getAuthToken } from "../../lib/api";
import { useSavedAdsStore } from "../../lib/savedAdsStore";
import MarketMap from "../components/MarketMap";
import {
  categoryLabel,
  groupPrice,
  locationLabel,
  priceParts,
  repairmentLabel,
  typeLabel,
} from "../format";

// Listing detail (mockup #/u-listing): gallery + lightbox, spec rail, live
// 3D tour (iframe over Ad.tour3dLink — guaranteed absolute http(s) by the
// API), description, nearby chips, location pin, and the price box with the
// publishing agent's contact. Booking stays phone-first: lead creation is an
// authenticated CRM call, so the public surface reveals the number instead.
function ListingDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [ad, setAd] = useState(null);
  const [agent, setAgent] = useState(null);
  const [missing, setMissing] = useState(false);
  const [showPhone, setShowPhone] = useState(false);
  const [lightbox, setLightbox] = useState(false);
  const { savedIds, toggleSaved } = useSavedAdsStore();

  useEffect(() => {
    setAd(null);
    setAgent(null);
    setMissing(false);
    setShowPhone(false);
    apiClient.ads
      .getById(id)
      .then((data) => {
        setAd(data);
        if (data.agentId) {
          apiClient.agents
            .getById(data.agentId)
            .then(setAgent)
            .catch((error) => console.error(error));
        }
      })
      .catch((error) => {
        console.error(error);
        setMissing(true);
      });
  }, [id]);

  if (missing) {
    return (
      <div className="wrap">
        <div className="empty">
          <House size={38} />
          <b>This listing is no longer available</b>
          <p>It may have been sold or taken down by the agent.</p>
          <button className="btn btn--dark" style={{ marginTop: 16 }} onClick={() => navigate("/list")}>
            Browse other listings
          </button>
        </div>
      </div>
    );
  }

  if (!ad) {
    return (
      <div className="wrap">
        <div className="gal" style={{ marginTop: 22 }}>
          <div className="skeleton" style={{ minHeight: "100%" }} />
          <div className="skeleton" style={{ minHeight: "100%" }} />
        </div>
      </div>
    );
  }

  const photos = ad.photos ?? [];
  const price = priceParts(ad);
  const perSqm = ad.category === "sale" ? computePricePerSqm(ad.price, ad.area) : null;
  const saved = savedIds.has(ad.id);
  const reference = ad.reference || `#${ad.id.slice(0, 5)}`;
  const repairment = repairmentLabel(ad);
  const nearby = Array.isArray(ad.nearPlacesList) ? ad.nearPlacesList.filter(Boolean) : [];

  const onFav = () => {
    if (!getAuthToken()) {
      navigate("/login");
      return;
    }
    toggleSaved(ad.id);
  };

  return (
    <div className="wrap">
      <div className="backrow">
        <button className="iconbtn" onClick={() => navigate(-1)} aria-label="Back">
          <ArrowLeft size={17} />
        </button>
        <span className="sub">
          Search / {ad.district || ad.city} / <b>{reference}</b>
        </span>
      </div>

      <div className="gal">
        <div
          className="gal__m"
          style={photos[0] ? { backgroundImage: `url(${photos[0]})` } : undefined}
        />
        <div className="gal__s">
          <div style={photos[1] ? { backgroundImage: `url(${photos[1]})` } : undefined} />
          <div style={photos[2] ? { backgroundImage: `url(${photos[2]})` } : undefined}>
            {photos.length > 3 && (
              <button className="gal__more" onClick={() => setLightbox(true)}>
                + {photos.length - 3} photos
              </button>
            )}
          </div>
        </div>
      </div>

      {lightbox && (
        <div className="lightbox" onClick={() => setLightbox(false)}>
          <button className="lightbox__close" aria-label="Close gallery">
            <X size={20} />
          </button>
          <div className="lightbox__grid">
            {photos.map((url) => (
              <img key={url} src={url} alt={ad.title} />
            ))}
          </div>
        </div>
      )}

      <div className="detail">
        <main>
          <div style={{ display: "flex", gap: 8, marginBottom: 12 }}>
            <span className="chip is-on" style={{ padding: "6px 13px", fontSize: 11 }}>
              {categoryLabel(ad)}
            </span>
            <span className="chip" style={{ padding: "6px 13px", fontSize: 11 }}>
              {typeLabel(ad)}
            </span>
          </div>
          <h1 className="h1">{ad.title}</h1>
          <div className="card__loc" style={{ fontSize: 13, marginTop: 9 }}>
            <MapPin size={14} /> {locationLabel(ad)}
            {ad.createdAt && <> · Listed {formatCreatedAt(ad.createdAt)}</>}
          </div>

          <div className="specrail">
            {ad.rooms != null && (
              <div className="spec">
                <BedDouble size={18} />
                <b className="num">{ad.rooms}</b>
                <span>Rooms</span>
              </div>
            )}
            {ad.area != null && (
              <div className="spec">
                <Ruler size={18} />
                <b className="num">{ad.area} m²</b>
                <span>Total area</span>
              </div>
            )}
            {ad.storey != null && (
              <div className="spec">
                <Building2 size={18} />
                <b className="num">
                  {ad.storey}
                  {ad.floors != null && ` / ${ad.floors}`}
                </b>
                <span>Floor</span>
              </div>
            )}
            {repairment && (
              <div className="spec">
                <Hammer size={18} />
                <b>{repairment}</b>
                <span>Repairment</span>
              </div>
            )}
          </div>

          {ad.tour3dLink && (
            <div className="block">
              <h3>Live 3D tour</h3>
              <div className="tourframe">
                <iframe
                  title="3D tour"
                  src={ad.tour3dLink}
                  allow="xr-spatial-tracking; gyroscope; accelerometer"
                  allowFullScreen
                />
              </div>
            </div>
          )}

          {ad.description && (
            <div className="block">
              <h3>About this property</h3>
              <p style={{ whiteSpace: "pre-line" }}>{ad.description}</p>
            </div>
          )}

          {nearby.length > 0 && (
            <div className="block">
              <h3>What&rsquo;s nearby</h3>
              <div className="nearby">
                {nearby.map((place) => (
                  <span key={place} className="nb">
                    <MapPin size={14} /> {place}
                  </span>
                ))}
              </div>
            </div>
          )}

          {ad.lat !== null && ad.lng !== null && (
            <div className="block">
              <h3>Location</h3>
              <div className="mapbox mapbox--inline">
                <MarketMap ads={[ad]} activeId={ad.id} />
              </div>
            </div>
          )}
        </main>

        <aside className="side">
          <div className="pricebox">
            <div className="pricebox__l">Asking price</div>
            <div className="pricebox__v num">
              {price.body}
              {price.suffix && <small>{price.suffix}</small>}
            </div>
            {perSqm !== null && (
              <div className="pricebox__m num">
                {ad.priceType === "uzs" ? `${groupPrice(perSqm)} UZS` : `$${groupPrice(perSqm)}`} / m²
              </div>
            )}
            {agent && (
              <div className="agentrow">
                <div
                  className="agentrow__av"
                  style={agent.avatar ? { backgroundImage: `url(${agent.avatar})` } : undefined}
                >
                  {!agent.avatar && <UserRound size={20} />}
                </div>
                <div>
                  <b>{agent.fullName}</b>
                  <span className="num">
                    Agent · {agent.adsCount} listings · {agent.dealsClosedCount} closed
                  </span>
                </div>
              </div>
            )}
            <div className="stack" style={{ marginTop: agent ? 0 : 16 }}>
              {agent?.phoneNumber &&
                (showPhone ? (
                  <a className="btn btn--p" href={`tel:${agent.phoneNumber}`}>
                    <Phone size={15} /> {agent.phoneNumber}
                  </a>
                ) : (
                  <button className="btn btn--p" onClick={() => setShowPhone(true)}>
                    <Phone size={15} /> Show phone number
                  </button>
                ))}
              {agent && (
                <button className="btn btn--g" onClick={() => navigate(`/agent/${agent.id}`)}>
                  <UserRound size={15} /> View agent profile
                </button>
              )}
              <button className="btn btn--g" onClick={onFav}>
                <Heart size={15} fill={saved ? "currentColor" : "none"} />
                {saved ? "Saved" : "Save this listing"}
              </button>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}

export default ListingDetailPage;
