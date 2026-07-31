// Runs on the La Casa app origin. Relays postMessage triggers to the
// background worker and answers presence pings. postMessage (not
// externally_connectable) keeps the extension id out of the web bundle —
// docs/07 §2.
import { EXT_SOURCE, PAGE_SOURCE, sendToBackground } from "../lib/messaging";
import type { PageCrosspostRequest, PagePing } from "../lib/messaging";

window.addEventListener("message", (event: MessageEvent) => {
  if (event.source !== window || event.origin !== window.location.origin) return;
  const data = event.data as PageCrosspostRequest | PagePing;
  if (!data || data.source !== PAGE_SOURCE) return;

  if (data.type === "CROSSPOST_PING") {
    window.postMessage({ source: EXT_SOURCE, type: "CROSSPOST_PONG", id: data.id }, window.location.origin);
    return;
  }

  if (data.type === "CROSSPOST_REQUEST") {
    const { channel, adId, ad, photoUrls, token, apiBase, requestId } = data;
    void sendToBackground({
      type: "CROSSPOST_REQUEST",
      job: { channel, adId, ad, photoUrls, token, apiBase },
    }).then((res) => {
      window.postMessage(
        {
          source: EXT_SOURCE,
          type: "CROSSPOST_RESULT",
          requestId,
          ok: res.ok,
          error: res.ok ? undefined : res.error,
        },
        window.location.origin,
      );
    });
  }
});
