# La Casa Cross-poster — browser extension

Autofills OLX.uz ad forms and Instagram web posts from a La Casa listing.
Implements `docs/07-olx-crosspost-extension.md` (OLX) and
`docs/09-instagram-onboarding.md` §2 extended to full automation (Instagram).

**The extension never clicks Publish/Share.** It fills the form/post; the
agent reviews everything and clicks the site's own publish button, then
self-reports the outcome via the injected banner.

## How it works

1. The React app (`src/services/crosspost.ts`) sends a `postMessage` trigger
   with the listing payload, photo URLs, API base and JWT.
2. `content/lacasa-bridge` relays it to the background service worker, which
   opens the target site in a new tab and stores the job in
   `chrome.storage.session` keyed by tab id.
3. The site content script (`olx-autofill` / `instagram-autofill`) shows a
   banner; on **Start** it snapshots the live DOM
   (accessibility-tree style, no raw HTML), sends it to
   `POST /api/publish/{channel}/map-fields` (server-side LLM, strict JSON
   schema), and executes the returned field actions with native-setter +
   synthetic events. Photos are fetched by the background worker and injected
   via `DataTransfer`.
4. Outcomes go to `POST /api/publish/{channel}/confirm`
   (`drafted` → `DRAFTED_AWAITING_REVIEW`, `published`/`failed`/`aborted`).

Guardrails: executor refuses submit-looking controls; per-agent daily caps
enforced server-side (OLX 15/day, IG 5/day); one session at a time + 3-min
cooldown; IG requires a one-time consent (`User.igAssistConsentAt`).

## Build

```sh
cd extension
npm install
npm run build      # -> extension/dist
npm run watch      # rebuild on change
```

## Load in Chrome

1. `chrome://extensions` → enable Developer mode.
2. "Load unpacked" → select `extension/dist`.
3. Log into OLX.uz / Instagram in the same browser profile.
4. Open the La Casa app (localhost:5273 or lacasa.uz) — the OLX / Instagram
   publish buttons detect the extension automatically.

`manifest.json` includes the localhost dev origins (`localhost:5273` app,
`localhost:4200` API, `localhost:9000` MinIO); strip them for a production
build/store submission.
