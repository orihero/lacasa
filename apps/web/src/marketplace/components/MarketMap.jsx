import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { MapContainer, Marker, TileLayer } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { priceParts } from "../format";

const TASHKENT = [41.311081, 69.240562];

// Leaflet map with the mockup's price-pill pins (`.pricepin`), rendered as
// divIcons so they style with the marketplace tokens. Only ads with a real
// pin are drawn — `lat !== null && lng !== null` per the api-client contract
// (a pin at latitude 0 is valid; don't falsy-check).
function pinIcon(ad, active) {
  const price = priceParts(ad);
  const label = `${price.body}${price.suffix ? "/mo" : ""}`;
  return L.divIcon({
    className: "",
    html: `<div class="pricepin${active ? " is-on" : ""}">${label}</div>`,
    iconSize: [0, 0],
  });
}

function MarketMap({ ads, activeId = null }) {
  const navigate = useNavigate();
  const pinned = useMemo(
    () => ads.filter((ad) => ad.lat !== null && ad.lng !== null),
    [ads],
  );

  const center = pinned.length ? [pinned[0].lat, pinned[0].lng] : TASHKENT;

  return (
    <MapContainer center={center} zoom={12} scrollWheelZoom={false}>
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      {pinned.map((ad) => (
        <Marker
          key={ad.id}
          position={[ad.lat, ad.lng]}
          icon={pinIcon(ad, ad.id === activeId)}
          eventHandlers={{ click: () => navigate(`/post/${ad.id}`) }}
        />
      ))}
    </MapContainer>
  );
}

export default MarketMap;
