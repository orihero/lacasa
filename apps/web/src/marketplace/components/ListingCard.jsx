import { useNavigate } from "react-router-dom";
import { BedDouble, Building2, Heart, MapPin, Ruler, Video } from "lucide-react";
import { useSavedAdsStore } from "../../lib/savedAdsStore";
import { getAuthToken } from "../../lib/api";
import {
  categoryLabel,
  floorLabel,
  locationLabel,
  priceParts,
} from "../format";

// One marketplace listing card (mockup .card). `compact` drops the spec row —
// the agent-profile grid uses that. Works for both the public `Ad` shape and
// the `SavedAd` rows (same field names on the wire).
function ListingCard({ ad, compact = false }) {
  const navigate = useNavigate();
  const { savedIds, toggleSaved } = useSavedAdsStore();
  const saved = savedIds.has(ad.id);

  const photo = ad.photos?.[0];
  const price = priceParts(ad);
  const floor = floorLabel(ad);

  const onFav = (event) => {
    event.stopPropagation();
    if (!getAuthToken()) {
      navigate("/login");
      return;
    }
    toggleSaved(ad.id);
  };

  return (
    <article className="card" onClick={() => navigate(`/post/${ad.id}`)}>
      <div
        className="card__ph"
        style={photo ? { backgroundImage: `url(${photo})` } : undefined}
      >
        <div className="card__top">
          <span className="card__tag g">
            {ad.tour3dLink ? (
              <>
                <Video size={12} /> 3D Tour
              </>
            ) : (
              categoryLabel(ad)
            )}
          </span>
          <button
            className={`card__fav g${saved ? " is-on" : ""}`}
            onClick={onFav}
            aria-label={saved ? "Remove from saved" : "Save listing"}
          >
            <Heart size={16} fill={saved ? "currentColor" : "none"} />
          </button>
        </div>
        <div className="card__price g num">
          {price.body}
          {price.suffix && <small>{price.suffix}</small>}
        </div>
      </div>
      <div className="card__b">
        <div className="card__t">{ad.title}</div>
        <div className="card__loc">
          <MapPin size={13} /> {locationLabel(ad)}
        </div>
        {!compact && (
          <div className="card__spec">
            {ad.rooms != null && (
              <span>
                <BedDouble size={14} /> {ad.rooms}
              </span>
            )}
            {ad.area != null && (
              <span>
                <Ruler size={14} /> {ad.area} m²
              </span>
            )}
            {floor && (
              <span>
                <Building2 size={14} /> {floor}
              </span>
            )}
          </div>
        )}
      </div>
    </article>
  );
}

export default ListingCard;
