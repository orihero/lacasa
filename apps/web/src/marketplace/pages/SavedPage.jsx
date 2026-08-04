import { useEffect } from "react";
import { Link } from "react-router-dom";
import { Heart } from "lucide-react";
import { useSavedAdsStore } from "../../lib/savedAdsStore";
import { getAuthToken } from "../../lib/api";
import ListingCard from "../components/ListingCard";

// Saved listings (mockup #/u-saved). Signed-out visitors get a sign-in CTA —
// hearts only persist against a session.
function SavedPage() {
  const { savedList, isLoading, loaded, fetchSaved } = useSavedAdsStore();
  const signedIn = Boolean(getAuthToken());

  useEffect(() => {
    // Refresh on entry: hearts toggled elsewhere only add ids optimistically,
    // the full rows come from GET /saved-ads.
    fetchSaved();
  }, [fetchSaved]);

  return (
    <div className="wrap pad">
      <div className="rowhead">
        <div>
          <h2 className="h2">Saved listings</h2>
          <p className="sub">
            {!signedIn
              ? "Sign in to keep the properties you like"
              : loaded && !isLoading
                ? `${savedList.length} propert${savedList.length === 1 ? "y" : "ies"} you've hearted`
                : "Loading…"}
          </p>
        </div>
      </div>

      {!signedIn ? (
        <div className="empty">
          <Heart size={38} />
          <b>Your saved listings live here</b>
          <p>Sign in and tap the heart on any listing to keep it.</p>
          <Link to="/login" className="btn btn--dark" style={{ marginTop: 16, display: "inline-flex" }}>
            Sign in
          </Link>
        </div>
      ) : (
        <>
          <div className="grid grid--4">
            {isLoading
              ? Array.from({ length: 4 }, (_, i) => <div key={i} className="skeleton" />)
              : savedList.map((ad) => <ListingCard key={ad.id} ad={ad} />)}
          </div>
          {loaded && !isLoading && savedList.length === 0 && (
            <div className="empty">
              <Heart size={38} />
              <b>Nothing saved yet</b>
              <p>Tap the heart on any listing and it will wait for you here.</p>
              <Link to="/list" className="btn btn--dark" style={{ marginTop: 16, display: "inline-flex" }}>
                Browse listings
              </Link>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default SavedPage;
