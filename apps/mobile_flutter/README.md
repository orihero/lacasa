# @lacasa/mobile_flutter

The La Casa Flutter client. Talks to `apps/api` like every other surface; the
binding screen spec is [`mockups/SCREENS.md`](../../mockups/SCREENS.md), which
fixes every screen id, label, enum wire value and navigation target so nothing
has to be invented.

This replaced an Expo/React Native prototype (deleted 2026-08-07) — see
`docs/05-migration-plan.md`.

## Running it

```bash
flutter pub get
flutter run          # or, from the repo root: npm run dev:mobile-flutter
flutter analyze      # must be clean
flutter test         # 944 passing, 0 failing (verified 2026-08-11) — the
                      # fixture/interface-drift caveat that used to live here
                      # is gone: whatever produced it has been fixed upstream
```

**Live, and only live.** Every repository provider constructs its
`Live<Feature>Repository` around a real `apps/api` (default
`http://localhost:4200/api`, see `lib/api/env.dart` to point it elsewhere).
There is no bundled fixture data and no fixtures/live switch: the app has one
data source.

This replaced an earlier arrangement in which each feature carried a
`data/<feature>_mode.dart` switch and a `Fixture<Feature>Repository` full of
hand-written seed rows, selected by `LACASA_USE_FIXTURES` or a per-feature
`LACASA_<FEATURE>_LIVE_API` define. Those files are deleted and those defines
no longer exist — passing them has no effect. **The app needs a running API to
show anything**; start one with `npm run dev:api`, and seed it with real
listings via `npm run seed:olx -w @lacasa/api` (see `apps/api/prisma/
seed-olx.js`).

Widget tests are unaffected by the removal, but the reason they are safe
changed. `flutter test` used to be handed fixtures automatically by
`app_mode.dart`'s `FLUTTER_TEST` guard, so a test could pump a screen with no
repository override and still not touch the network. That fallback is gone: a
test that pumps a screen **must** override that feature's repository provider
with a fake from `test/features/<feature>/support/`, or the screen will fire
real HTTP out of the test process.

## Layout

| Path | What |
|---|---|
| `lib/api/` | Typed API layer — client, transport, token storage, models, resources |
| `lib/navigation/` | `route_paths.dart` (every path, declared once), `app_router.dart` (go_router tree), role-aware tab shell |
| `lib/theme/` | Colour/spacing/radii/typography tokens + the liquid-glass surface |
| `lib/shared/` | Widgets and formatters used by more than one feature — including cross-feature-promoted ones like `NavRow`, `LabelledFormField`/`VisibilityToggle`, `FieldLabel`, `ChoiceChipGroup<T>`, `dialOrCopyPhone`, `RatingStars` and `LoadMoreFooter` (see the consolidation note under Known gaps); `shared/platform/` holds the seams onto real device capabilities — `LinkLauncher` (`url_launcher`/`share_plus`) and `MediaPicker` (`image_picker`), alongside `features/permissions/data/permission_gateway.dart`'s `PermissionGateway`, which stayed in its feature folder rather than moving here since `permissions-primer` is its only caller |
| `lib/features/<name>/` | One directory per feature: `data/` (repository + fixture/live impls), `state/` (Riverpod), `widgets/`, `formatters/` |
| `lib/l10n/` | Localization: `app_{en,uz,ru}.arb` (source of truth for every string + its `@key` description), `generated/` (committed `flutter gen-l10n` output), `README.md` (extraction conventions) and `GLOSSARY.md` (agreed en/uz/ru domain-term renderings). See Known gaps for status |
| `assets/promos/` | The app's only bundled images: Home's two `.promo` banner photographs, decoded out of the canonical mockup's own `window.PHOTOS` registry. Bundled because a promo has to be right on the first frame of a cold start and with no connection — listing photos stay remote, since those are content and change per ad |

`lib/features/home/` is the reference implementation of that layout — copy its
patterns rather than inventing new ones.

## Screen status vs. SCREENS.md

`route_paths.dart` declares **all 38** routes and `app_router.dart` wires the
whole tree, so every tab navigates somewhere. Screens not yet built render
`PlaceholderScreen`, which names the screen rather than faking content.

| # | Screen | Status |
|---|---|---|
| 1 | `onboarding` | **Built** — `/onboarding`; shown once, gated by `app_router.dart`'s redirect |
| 2 | `permissions-primer` | **Built** — `/permissions-primer`; "Allow" raises the real OS prompt for the Camera & Photos row; the Notifications row stays a deliberate `unavailable` stub (see gaps) |
| 3 | `home-feed` | **Built** |
| 4 | `listing-search` | **Built** — reachable at `/search` |
| 5 | `filter-sheet` | **Built** — a bottom sheet, not a route; opened from search's Filters button |
| 6 | `map-view` | **Built** — `/map-view`, from search's map toggle and `listing-detail`'s Location block |
| 7 | `listing-detail` | **Built** — `/home/listing/:id`, `/search/listing/:id`, `/agents/listing/:id`; Share/Call are real (`LinkLauncher`, copy-and-toast fallback); a `tour3dLink` on the ad shows a "Live 3D Tour" banner that pushes a real, origin-pinned webview; the agent block now shows the agent's address and rating too (see Known gaps) |
| 8 | `photo-gallery` | **Built** — `/photo-gallery`, pushed from `listing-detail`'s hero |
| 9 | `agents-directory` | **Built** — the Agents tab root, `/agents`; cards now show `address` and a real `"Review: {rating}/5"` row (see Known gaps for the closed agent-rating gap) |
| 10 | `agent-profile` | **Built** — one route per branch: `/agents/:id`, `/home/agent/:id`, `/search/agent/:id`; identity block gained address/rating too, plus a Reviews section with a leave/edit/delete-a-review sheet (an addition beyond SCREENS.md — see Known gaps) |
| 11 | `contact-sheet` | **Built** — a bottom sheet; `listing-detail`'s CTA and `agent-profile`'s Message button |
| 12 | `login` | **Built** — `/login`, a root-navigator modal |
| 13 | `register` | **Built** — `/register`, a root-navigator modal |
| 14 | `profile-signed-out` | **Built** — the Profile tab root when signed out |
| 15 | `profile-buyer` | **Built** — the Profile tab root for `role: "user"` |
| 16 | `profile-agent` | **Built** — the Profile tab root for `role: "agent"`/`"coworker"`; Connected Accounts/Messages rows now push the real `connected-accounts`/`messages` screens (§21/§23, built this pass) |
| 17 | `saved-listings` | **Built** — `/profile/saved` |
| 18 | `edit-profile` | **Built** — `/profile/edit` |
| 19 | `settings` | **Built** — `/profile/settings` and `/work/profile/settings` |
| 20 | `language-sheet` | **Built** — a bottom sheet, not a route; opened from every Language row |
| 21 | `connected-accounts` | **Built** — `/work/profile/connected-accounts` and `/profile/connected-accounts` (one screen, two routes); Instagram is fully live-shaped (media/follower/following counts, "Connect Instagram" now opens the OAuth URL in the external browser via `LinkLauncher`, per Meta's own restriction against an in-app WebView — falling back to copy-and-toast only if nothing on the device can open it), Telegram is a count-only row (no per-channel API), YouTube is a visibly-disabled "Beta" pair (see gaps) |
| 22 | `notifications` | **Built** — `/work/dashboard/notifications` and `/home/notifications`; `GET /notifications` backs live mode for real now (see Known gaps for what closed), contextual taps route to `lead-detail`/`edit-listing`/`publish-status`/`coworker-detail` per §22 |
| 23 | `messages` | **Built** — `/work/profile/messages` and `/profile/messages`; renders §23's own "coming soon, contact leads by phone" banner rather than a chat UI, exactly as specified |
| 24 | `dashboard` | **Built** — `/work/dashboard`, the Work tab's landing screen for `role: "agent"` (coworker sessions skip it, landing on `my-listings` instead, per §24's own note); the "Ads statistics" chart plots a real server-bucketed series and the coworker table's Sale count is a real number in both modes now (see gaps for what closed) |
| 25 | `my-listings` | **Built** — `/work/my-listings`, the Work tab's landing screen for `role: "coworker"`; wires `filter-sheet`'s CRM (`isCrm`) variant for Sort + Status; "infinite scroll" is real `GET /my/ads` keyset paging, and Status is a real server filter too |
| 26 | `create-listing` | **Built** — `/create-listing`, a root-navigator modal from `my-listings`' "+"; the full §26 field set (Address, Reference, Nearby chips, Additional Info, video) rather than `apps/console`'s reduced one; photo/video pickers are real (camera or gallery, via `MediaPicker`), with a client-side size check ahead of upload |
| 27 | `edit-listing` | **Built** — `/work/my-listings/edit-listing/:id`, **pushed** from `my-listings`' edit icon; nested under My Ads so a Back press (or a discard) reveals that list with its filters and paged scroll position intact, rather than a blank `/work`; same field set as `create-listing`, pre-filled, plus the publish section and Delete |
| 28 | `publish-channels-sheet` | **Built** — a bottom sheet, not a route; opened from `create-listing`/`edit-listing`'s per-channel publish buttons |
| 29 | `publish-status` | **Built** — `/work/my-listings/publish-status/:id`, **pushed** from `edit-listing`'s "Publish Status" link (a `go` would have replaced the branch stack and torn down a dirty form without its "Discard changes?" prompt — `PopScope` is a pop-only hook); Retry on a failed Telegram/Instagram row is wired for real, distinguishing every server rejection reason on screen; YouTube/OLX stay visibly disabled with their reason (see gaps) |
| 30 | `leads-list` | **Built** — `/work/leads` |
| 31 | `leads-kanban` | **Built** — `/work/leads/kanban`, from `leads-list`'s view toggle; card footer resolves and shows the assigned coworker's name whenever `Lead.coworkerId` is set (see Known gaps for what closed and why the old refusal was wrong) |
| 32 | `lead-detail` | **Built** — a bottom sheet, not a route; opened from `leads-list`/`leads-kanban` row taps and from a lead `notification` tap |
| 33 | `create-lead` | **Built** — `/work/leads/create`, from `leads-list`/`leads-kanban`'s "+ Add new lead" |
| 34 | `kanban-move-sheet` | **Built** — a bottom sheet, not a route; opened by `leads-kanban`'s long-press "Move to…" only when the destination needs a call-back time or a conversation note, per §34 |
| 35 | `coworkers-list` | **Built** — `/work/coworkers`, agent role only; hidden entirely (no "+ Add new coworker") for a SOLO-kind agent, matching the server's own `solo_realtor` 403 |
| 36 | `coworker-detail` | **Built** — `/work/coworkers/:id`; listings-count/last-active come from the server's own `GET /statistics/coworkers/summary` aggregate now, avatar upload is real for an AGENT (managing) session (see gaps) |
| 37 | `add-coworker` | **Built** — `/work/coworkers/create`, from `coworkers-list`'s "+" |
| 38 | `delete-confirm` | **Built** — a shared helper (`confirmDelete` in `shared/widgets/delete_confirm.dart`), not a route; called from `edit-listing`/`lead-detail`/`coworker-detail`'s Delete buttons |

**All 38 SCREENS.md screens are now built.** The Work/CRM tab (§21–§38) is
in place behind an agent/coworker session — connected accounts,
notifications, messages, the dashboard, My Ads with its CRM filter sheet,
the full create/edit-listing flow with its publish sheet and status screen,
leads (list, kanban, detail sheet, create, the kanban move sheet) and
coworkers (list, detail, add) — on top of the signed-out surface, auth and
the whole Profile branch already built before it. A later integration pass
made every remaining platform stand-in real: photo/video/avatar pickers
(`image_picker`), tel/share/OAuth-open affordances (`url_launcher`/
`share_plus`), the Camera & Photos permission prompt (`permission_handler`),
listing-detail's 3D tour (`webview_flutter`), and map-view's pin clustering
(`flutter_map_marker_cluster`). What is left is not a missing screen: it's
the gaps below — chiefly the Notifications *permission* row and the Settings
push toggle (no push-messaging plugin exists to back either, see gaps) — and
a handful of remaining server-side data gaps that no client-side code can
close honestly on its own. The agent `address`/rating gap that used to be
listed here is closed — see Known gaps below. `search`/`filter`'s own
former gaps — client-side search/sort/pagination and the missing region
vocabulary — are closed as of this slice too (`GET /ads`'s `q`/`sort`/
paging, `GET /regions`); so is the dashboard's chart, the coworkers
cluster's "listings count"/"last active"/"Sale count" (`GET
/statistics/ads/series`, `GET /statistics/coworkers/summary`), `my-listings`'
pagination, publish retry for Telegram/Instagram, and — this integration
pass — the `notifications` feed's live backend (`GET /notifications`) and the
contact form's fixtures-by-default danger (both `notifications` and
`contact` now default to live like everything else, see Known gaps below for
what each closed and didn't).

`auth_session.dart` is real as of this slice: `signInWithPassword`/
`registerAccount`/`signOut` call through to `AuthRepository`
(`features/auth/`, live/fixture switch), and a persisted token is restored
on launch — see that file's own doc comment for the two-phase (sync
keystore check, then bounded async validation) design.

`listing-detail` is declared once per shell branch rather than as one
top-level route, because SCREENS.md §1 lists it under "Pushed (full-screen,
back-stack)" — it keeps the tab bar and stays in the back stack of whichever
tab it was opened from. It takes a `branchPrefix` so the sibling routes it
pushes (`agent-profile`) resolve into that same branch.

`tour-3d-view` (`/tour-3d-view`) is a no-chrome, root-navigator route
alongside `photo-gallery`/`map-view` — not one of SCREENS.md's 38 numbered
screens, since it exists to surface `Ad.tour3dLink`, a field SCREENS.md §7
already specs but the app previously left unsurfaced entirely (see the old
"gaps" entry this replaced). Same-origin navigation guard and a render-side
scheme check independent of the server's own — see
`tour3d_view_screen.dart`'s doc comment.

### Known gaps

- ~~`permissions-primer`'s "Allow" does not raise an OS prompt~~ **Closed for
  Camera & Photos.** `permission_handler` plus `CAMERA`/`READ_MEDIA_IMAGES`/
  `READ_MEDIA_VIDEO` in `AndroidManifest.xml` and the matching `Info.plist`
  usage descriptions now back the row, since `create-listing`/`edit-listing`'s
  photo/video pickers and the three avatar controls genuinely need them —
  see `features/permissions/data/permission_gateway.dart`'s
  `PermissionHandlerGateway`. **The Notifications row is still
  `PermissionOutcome.unavailable`, and stays that way on purpose — this is
  still true even though `apps/api` gained real push plumbing this session**
  (a `DeviceToken` table, `POST`/`DELETE /push/devices`, and a
  `pushService` wired into the real lead/sold/publish trigger points — see
  the Notifications-toggle gap below for the full picture). None of that
  reaches this screen: `POST_NOTIFICATIONS` is still **not** declared in
  the manifest, and `permission_gateway.dart`'s short-circuit to
  `PermissionOutcome.unavailable` is untouched on purpose, because
  `apps/api`'s new send path (`pushService.js#sendPushToUser`) itself
  degrades to a logged no-op until FCM credentials are configured — which
  they never are today, see the toggle gap below for what that actually
  requires. Requesting a permission for a capability that still can't
  deliver a single message is what store review flags, not what earns
  trust.
- ~~`map-view` does not cluster pins~~ **Closed.** Overlapping pins now merge
  via `flutter_map_marker_cluster` (the honest fix this note used to call
  for, not a hand-rolled density approximation), restyled in this app's
  tokens — see `features/map_view/widgets/map_cluster_marker.dart`. The
  screen still reports `"n of m on the map"` whenever some results have no
  coordinates and therefore cannot be drawn at all, and now shows an
  explanatory card instead of a silent empty map when zero results have one.
- ~~No agent `address` or rating~~ **Closed.** `User` gained an `address`
  column and a real `agent_reviews` table backs `ratingAverage`/
  `ratingCount` now (`GET /agents`/`GET /agents/:id`, plus
  `GET /agents/:id/reviews`, `POST /agents/:id/reviews`,
  `DELETE /agents/:id/reviews/me`). SCREENS.md §3.9's address line and
  `"Review: {rating}/5"` star row render on the directory card, the
  `agent-profile` identity block, and `listing-detail`'s agent block —
  `shared/widgets/rating_stars.dart`'s `RatingStars`. **`ratingAverage ==
  null` still renders "No reviews yet", never a zero-star row** — that null
  is the whole reason this gap was refused rather than faked the first time
  around, and the fix preserves it rather than papering over it now that
  real data exists.

  A full leave/edit/delete-a-review surface (`agent_review_sheet.dart`,
  opened from `agent-profile`'s new Reviews section) ships alongside the
  display. **This is beyond SCREENS.md** — §3.9 only specs the rating
  *display*, not a submission form, since there was no review table to
  submit into when the spec was written; `mockups/SCREENS.md` should gain a
  §3.9a (or similar) describing it. Two honest limitations, both
  documented at their call sites rather than worked around: (1) "Edit your
  review" only recognizes an existing review that happens to be on an
  already-loaded page of the list — there is no `GET /agents/:id/reviews/me`
  endpoint to ask directly, so a review from long enough ago that it has
  scrolled past the loaded pages shows "Leave a review" instead until the
  user pages down to it (the server's own upsert-on-`(agentId, authorId)`
  means this never creates a duplicate, only mislabels a button); (2) the
  client pre-empts the server's self-review 403 for the common case (typed
  from the caller's `AuthUser` when it's the same person as the profile),
  but cannot for a race with another device, which still surfaces the
  server's real 403 with real copy.
- ~~Several platform affordances are stand-ins, not the real thing~~
  **Closed.** `url_launcher`/`share_plus` are both in `pubspec.yaml` now,
  reached through `shared/platform/link_launcher.dart`'s `LinkLauncher`
  seam: `listing-detail`'s share button hands the OS share sheet a real
  title/price/link payload; every call button (`listing-detail`'s agent
  block, `agent-profile`'s Call action, `profile-agent`'s phone row —
  the byte-identical logic across all three is now
  `shared/widgets/dial_or_copy.dart`'s `dialOrCopyPhone`) dials a real
  `tel:` intent; `profile-buyer`'s "Register as Agent" and
  `connected-accounts`' "Connect Instagram" (§21) open their URLs in the
  external browser. None of these treat a device that can't do it as a dead
  end — no dialer, no browser, or the OS declining the intent all fall back
  to the previous copy-and-toast behaviour, with the toast saying so
  honestly rather than pretending the tap did nothing.
- ~~`language-sheet` stores a preference nothing reads yet~~ ~~most screens'
  strings are not through it yet~~ **Done — but read the machine-translation
  caveat below before shipping.** `flutter_localizations` and `intl` are in
  `pubspec.yaml`, `l10n.yaml` generates `AppLocalizations` into
  `lib/l10n/generated/` (committed — see that file's own header comment for
  why) from `lib/l10n/app_{en,uz,ru}.arb`, and `app.dart` watches
  `languageProvider` and drives `MaterialApp.locale` from it. Every screen's
  user-visible English string is extracted (683 ARB keys as of the
  integration pass that reconciled six agents' work — 688 minus seven
  duplicate `"Retry"` keys consolidated onto the pre-existing
  `sharedRetryLabel`, plus two for a genuine miss: `language-sheet`'s own
  title/close button had been left hardcoded, see `lib/l10n/README.md`'s
  extraction-groups note) and translated into all three locales — no
  English-fallback keys.

  **uz/ru are machine-translated and have not had a native-speaker review
  pass.** This is the most important caveat here: every string reads as
  plausible, grammatically-agreeing Uzbek/Russian to a non-native reviewer
  and passed every automated check this run could devise (glossary
  consistency, plural-category completeness, byte-identical English), but
  none of that substitutes for a native speaker reading the shipped copy in
  context. Budget a review pass — ideally against the running app, not the
  ARB files in isolation — before this ships to real Uzbek/Russian-speaking
  users.

  **Proven, not just asserted, three ways** (`test/l10n/` and
  `test/features/language/`):
  - **The switch is live.** Picking En/Uz/Ru in the sheet changes the app
    locale the same frame, no restart —
    `language_sheet_test.dart`'s `'selecting a language changes the live
    app locale, no restart needed'`.
  - **The choice survives a restart.** `language_provider_test.dart` proves
    a selection written by one `ProviderContainer` (one app launch, in
    Riverpod terms) is read back correctly by a fresh one sharing the same
    backing store — the actual persistence contract
    `secure_language_repository.dart` promises, not just that `save`/`load`
    were called.
  - **The content is real, not just present.** `three_locale_rendering_proof_test.dart`
    pumps real screens under `en`/`uz`/`ru` and asserts the *visible* text
    differs per locale and is never the silent English fallback a missing
    ARB key produces — covering a plural (`listingRoomsCount`'s Russian
    one/few/many/other categories), a placeholder
    (`settingsAboutRowSubtitle`'s "Version {version}"), and a form's
    validation messages (`edit-profile`'s required-field/phone-format
    errors, SCREENS.md §18).

  **Longer-language layout checked, one real overflow found and fixed.**
  Russian runs 30-50% longer than English and Uzbek can run longer still, so
  this pass re-ran the existing "layout holds at real phone widths"
  (360/390/430px) overflow groups under `ru`/`uz` too, across the highest-risk
  screens (forms, chip rows, toolbars) — not just `en` as before. One real
  defect surfaced: `register`'s Solo agent/Agency chip row was a bare `Row`
  that fit English's "Solo agent"/"Agency" at every width but overflowed by
  16px under Russian's longer "Частный риелтор"/"Агентство" at 360px: fixed
  by switching it to `Wrap` (`register_screen.dart`), matching the pattern
  the same file's team-size chip row already used. Every other screen
  checked (settings, edit-profile, saved-listings, my-listings,
  notifications, connected-accounts, language-sheet, login) held with no
  overflow under either locale.

  A handful of strings are deliberately left as English/passthrough and
  reported as such in `lib/l10n/README.md`'s "what not to extract" rule:
  server-authored `ApiErrorBody.message` text, bundled fixture/seed data,
  the "La Casa" brand name, wire-value enums, and two genuine cross-group
  blockers flagged inline where they live — `contact/data/contact_prefill.dart`'s
  pre-filled message builders and `shared/state/uploads_repository.dart`'s
  `describeUploadError` — both left un-localized because migrating them
  would require a signature change reaching into another feature group's
  files (`listing_editor/widgets/form/photos_step.dart`,
  `shared/widgets/avatar_upload_control.dart`); still true as of this
  integration pass, not yet closed.
  `lib/l10n/GLOSSARY.md` fixes the en/uz/ru rendering of this product's
  domain terms; this pass re-checked it against all 683 keys and corrected
  three drifts it found — `reviewsRatingRequiredError` used "baho"/"оценку"
  (grade/mark) instead of the glossary's "reyting"/"рейтинг" for the numeric
  star rating, `permissionsNotificationsRowBody` (uz) said "nashr holati"
  where every other "publish status" string says "e'lon qilish holati", and
  `listingEditorPriceTypeFieldLabel` (uz) said the literal "Narx turi"
  ("price type") for what the field actually is — a currency selector — where
  the Russian string already correctly said "Тип валюты" ("currency type").
  `mockups/SCREENS.md`'s preamble still says the app's copy is English —
  that line predates this pass and is now out of date; not edited here since
  the spec is shared across three implementations, but it should say
  something like "copy is in `lib/l10n/`, En/Uz/Ru" instead.
- **`settings`' Notifications toggle still has nothing to switch on — the
  server half of push exists now, the client half deliberately doesn't.**
  `apps/api` gained a `DeviceToken` model (`prisma/schema.prisma`), `POST`/
  `DELETE /push/devices` (`routes/push.js`) and a `pushService.js` wired
  into the real trigger points — an `ActivityEvent` write for a new/moved
  lead or a sold ad, and every Telegram/Instagram publish outcome — so the
  four kinds `GET /notifications` already serves as a pull feed now have a
  real push counterpart to fire alongside them. But `pushService.js#sendPushToUser`
  is written to **never fail the write that triggered it** and degrades to
  a logged no-op whenever `FCM_SERVER_KEY` is unset (`config.js`'s
  `PUSH_CONFIGURED`) — which today it always is, because nothing has
  configured it yet. Nothing on the Flutter side changed at all, on
  purpose: no messaging plugin in `pubspec.yaml`, `POST_NOTIFICATIONS`
  still undeclared, `permission_gateway.dart`'s short-circuit untouched (see
  above), and this toggle still just persists a local preference and says
  on screen that nothing is delivered yet, rather than flipping silently
  and implying a subscription that does not exist.

  **Four things a human has to supply that no code in this repo can
  produce**, before any of the above can go live: a Firebase project (to
  mint the FCM credentials `pushService.js` needs); the resulting
  `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
  config files the client-side messaging plugin would need bundled; an
  APNs key for iOS delivery, which needs a paid Apple Developer Program
  membership to generate; and a `firebase-admin` service-account key for
  `apps/api` itself (or, if `pushService.js`'s current legacy-HTTP
  `FCM_SERVER_KEY` approach is kept instead of migrating to the modern
  Admin SDK, just that legacy server key from the same Firebase project).

  **Once those land, a future developer's list is short and mechanical**:
  add a messaging plugin (`firebase_messaging` or equivalent) to
  `pubspec.yaml`; declare `POST_NOTIFICATIONS` in `AndroidManifest.xml`
  (and register for remote notifications on iOS); remove
  `permission_gateway.dart`'s short-circuit so `AppPermission.notifications`
  routes through the plugin like Camera & Photos already does; call the
  now-real `POST /push/devices` with the token the plugin hands back
  (nothing in `UploadsResource`/`api.dart` has to change — this is a new
  resource call, not a rewire); and set `FCM_SERVER_KEY` in `apps/api`'s
  environment, which is the one step that flips `pushService.js` from a
  logged no-op to actually delivering. Being this exact about the ordering
  is the point of this entry: it's what stops someone shipping a
  permission prompt for a capability that still can't deliver anything the
  moment before that last step lands.
- **Sign-out clears the session even if the keystore write fails, and says so.**
  `flutter_secure_storage`'s `delete` is a platform channel and can throw; the
  in-memory session is dropped unconditionally, but a stored token that
  survives would sign the account back in on next launch, so the failure is
  surfaced to the user rather than swallowed. See `AuthSessionNotifier.signOut`.
- ~~`contact-sheet` reports success without sending unless the live switch is
  on~~ **Closed by deleting the fixture repositories.** The dangerous case
  ("Message sent successfully." for a message that reached nobody) needed
  fixture mode, and there is no longer any such mode to be in — `contact`,
  like every other feature, has exactly one implementation and it posts to
  the API (see "Running it" above). Widget tests inject an explicit fake, so
  no test can send a real message. Live, the server still answers 503
  `contact_unconfigured` unless
  `TG_CONTACT_CHAT_ID` is set — the sheet surfaces that distinctly rather
  than as a generic failure, since no amount of retrying fixes it.
- ~~The message field is capped at 200 characters, the server allows 2000~~
  **Closed.** SCREENS.md §3.11, `packages/domain`'s `contactSchema` (the zod
  boundary `apps/api`'s `POST /contact` actually validates against,
  `routes/contact.js`) and this app's `contactMessageMaxLength` are all
  reconciled onto the same number now: **500**, not the old 200 or 2000.
  `contact_sheet.dart`'s own doc comment records why 500: 200 was too tight
  for a realistic property enquiry (a move-in date, a budget and a question
  already runs past 230 characters), and 2000 was a server ceiling nobody
  had actually built a client against. `apps/web`'s dedicated Contact-Us page
  form (`ContactUs.jsx`) matches at 500 too — but its footer's near-duplicate
  contact form (`Footer.jsx`) still has `maxLength="200"`, a residual
  inconsistency in that surface this pass didn't touch (outside this file's
  ownership to fix, noted here only so this entry doesn't overstate "web" as
  one reconciled thing when it's really two forms, one still stale).
- ~~`listing-search` filters and sorts client-side~~ **Closed.** `GET /ads`
  gained `?q=`, a whitelisted `?sort=`, and opt-in keyset paging
  (`docs/04-api-spec.md`'s Ads section); `search_repository.dart` sends all
  three server-side now, and the results list's "infinite scroll" is a real
  paged fetch loop (`SearchResultsNotifier.loadMore`,
  `search_results_list.dart`) rather than lazy widget building over an
  already-complete list.
- ~~No region/district data~~ **Closed.** `GET /regions` now serves the
  `@lacasa/domain` region/district vocabulary over HTTP
  (`regions_repository.dart`); `filter-sheet`'s City/District fields are a
  cascading picker sourced from it (`filter_city_district_section.dart`),
  cached for the process lifetime rather than re-fetched on every sheet open
  (`regions_repository_provider.dart#regionsDataProvider`). Fixture mode
  bundles a small vocabulary matched to this build's own seed ads
  (`filter_regions_fixtures.dart`) rather than the real 203-district one —
  see that file's doc comment for why a subset with the *real* official
  (Uzbek-language) names would have silently broken fixture-mode filtering
  instead.
- ~~`create-listing`/`edit-listing`'s photo and video pickers, and every
  avatar uploader, cannot pick a file~~ **Closed.** `image_picker` is in
  `pubspec.yaml`; `shared/platform/media_picker.dart`'s `MediaPicker` seam
  backs `create-listing`/`edit-listing`'s photo and video steps and all
  three avatar controls (`edit-profile`, `coworker-detail` for an AGENT
  session, `add-coworker`). A picked file is checked against a client-side
  size ceiling (5MB photo / 70MB video — SCREENS.md §26; there is no
  server-side limit) before ever reaching `UploadsResource.presign`, and a
  cancelled OS picker is silently a no-op rather than an error, per
  `MediaPicker`'s own `null`-means-cancelled contract.
  ~~One corner is still open: none of the three avatar controls block Save
  while a pick+upload is still in flight~~ **Closed.**
  `AvatarUploadControl` gained a required `onUploadStateChanged` callback —
  fires the instant a pick turns into an upload (before the upload even
  starts) and clears once it settles (success, failure, or a picker cancel
  never reaches it at all). All three call sites (`edit-profile`,
  `add-coworker`, `coworker-detail`) track it and block Save with
  **"Please wait for the photo to finish uploading."** while `true`, the
  same shape `create-listing`/`edit-listing`'s existing
  `hasPendingUploads` check already used — a blocked Save rather than an
  awaited in-flight upload, chosen to match that established precedent
  rather than invent a second pattern for the same race.
- ~~The dashboard's "Ads statistics" chart has no charting library, and in
  live mode is not a daily series~~ **Closed.** `GET /statistics/ads/series`
  now exists and returns a real, server-bucketed day/hour series
  (`WORK_TAB_CONTRACT.md` §7.1, superseded) — still no charting library
  (`ads_statistics_panel.dart`'s plain `CustomPainter` stays, matching
  `apps/console`'s own choice not to pull one in for one screen), but both
  fixture and live mode now plot the same real `AdsSeries` shape through one
  rendering path, with axis labels formatted by the response's own
  `granularity` (hour vs day) rather than assuming a daily series. Fixture
  mode's series is still built from the real §4.6 seed points
  (`workDashboardChartFixture`), just wrapped in the same shape live data
  arrives in instead of read directly by the widget. **Found while verifying
  this endpoint against a running server, not by reading source alone**: the
  bucketed series endpoint genuinely has no all-time mode (an unbounded
  series has no sane bound on response size) and silently defaults to
  `today` when `filterType` is omitted — left alone, selecting "All" on the
  dashboard's time-range selector would have shown correct all-time stat
  tiles next to a chart quietly showing only today, the same screen
  disagreeing with itself about what "All" means. `LiveDashboardRepository
  .fetchAdsSeries` now remaps `StatisticsFilter.all` to `.thisMonth` for the
  series call only (the stat tiles keep the real all-time mode
  `fetchAdsStatistics` has) — matching what `FixtureDashboardRepository`
  already did for `.all`, not inventing a new convention.
- ~~`notifications` has no backend at all~~ **Closed.** `GET /notifications`
  now exists server-side (`WORK_TAB_CONTRACT.md` §7.11, superseded) —
  `LiveNotificationsRepository` calls it directly instead of synthesizing a
  feed from `GET /leads` + `GET /my/ads` + `GET /statistics/coworkers` +
  `GET /coworkers`, which also closes that old synthesis's real limitation:
  it could only honestly cover 3 of SCREENS.md §4.4's 4 notification kinds
  (`publish` needed `lastAttemptAt`, which `PublishResource.statusForAds`
  doesn't expose; the server's own implementation reads it directly and has
  no such gap). `unread` is computed server-side against whatever `since`
  the caller sends, not a stored flag — there is still no persisted
  read-state table anywhere in `apps/api`, by design (see
  `notificationService.js`'s own header comment) — so this client persists
  its own client-side watermark (`notifications_watermark_repository.dart`,
  `flutter_secure_storage`-backed) across visits and sends it as `since`,
  omitting it entirely on a genuine first-ever visit so everything honestly
  comes back unread.
- **YouTube and OLX are not actually publishable from this app.**
  `PublishResource` has no direct-publish call for YouTube — only
  `reportYoutube`, a report-back for an upload that happened somewhere else
  entirely, which this app has no mechanism to perform — and OLX
  cross-posting needs the browser extension `apps/console` already ships,
  which has no mobile equivalent (`WORK_TAB_CONTRACT.md` §7.3). Both render
  as visibly-disabled controls with the reason stated on screen
  (`publish-channels-sheet`, `create-listing`/`edit-listing`'s publish
  buttons, `connected-accounts`'s YouTube section) rather than pretending to
  work. Facebook Marketplace is omitted from the publish surface entirely,
  same as `apps/console` — no compliant automation path exists for either.
- **`publish-status`'s Retry is wired for Telegram/Instagram, closed
  2026-08-11.** `POST /publish/ads/:adId/:channel/retry` now exists and
  replays the exact original request server-side, so it's a genuinely
  different call from a fresh `publishInstagram`/`publishTelegram` — no
  more risk of silently re-deriving different input (`WORK_TAB_CONTRACT.md`
  §7.3, closed). The control is enabled only for the two channels with a
  real server-to-server call to replay; the server also 409s a
  `PUBLISHED` row (retry would double-post) and a `DRAFTED_AWAITING_REVIEW`
  one (a human may be mid-flight), and 400s a stale/never-failed row — each
  a distinct `ApiErrorException.code` the screen renders as its own
  message, not one generic "failed" toast. YouTube (no server-side publish
  call at all — only a report-back for a browser upload) and OLX (needs the
  desktop browser extension, no mobile equivalent) stay visibly disabled
  with their stated reason, same as `apps/console`.
- ~~Coworkers' "listings count"/"last active"/"Sale count" are derived
  client-side, and one of them is a permanent em dash~~ **Closed.**
  `Coworker` still carries only 5 fields on the wire (no count, no activity
  timestamp, no deal total) — but `GET /statistics/coworkers/summary` now
  folds that server-side into one row per coworker
  (`WORK_TAB_CONTRACT.md` §7.6, superseded), and `coworkers-list`/
  `coworker-detail` read it directly instead of folding
  `AgentAdsResource.myList()`/`StatisticsResource.coworkers()` themselves.
  **"Sale count"/"deals closed" was wrongly judged to have no backing data
  at all** — there's still no `LeadStatus.SUCCESS`-shaped status, but
  `ActivityEventStage.adSold` events always carried `coworkerId`; the
  dashboard's coworker table now folds that stage from the same event
  stream it already reads for "Ads count" (`CoworkerStatRow.saleCount`),
  and the summary endpoint's own `adsSoldCount` covers the same figure for
  `coworkers-list`/`coworker-detail`. A genuinely-zero count now renders
  `0`, not an em dash — the dash is reserved for a fetch that hasn't
  resolved, per this app's honesty rule.
- ~~`leads-kanban`'s card footer has no assigned-coworker identity to
  show.~~ **Closed — and the original refusal was wrong.** This entry used
  to claim `Lead` carries no agent-identity field distinct from its own
  `agentId`/`coworkerId`; that premise doesn't hold. `Lead.coworkerId` is a
  real, populated field (`leadService.js#serializeLead`, the same
  empty-string-means-none convention as `Ad.coworkerId`), set from the
  acting user on create when they're a COWORKER — and since leads are
  agent-scoped, not coworker-scoped, a coworker's own board shows the
  *whole team's* leads, so resolving that id is the only place on that
  board that tells them who owns a card. `kanban_card.dart`'s
  `_CoworkerFooter` resolves it against the already-cached
  `coworkersListProvider` roster — the same plain provider `coworkers-list`
  itself reads, so this triggers no fetch of its own — see
  `WORK_TAB_CONTRACT.md` §7.8, which records the same correction rather
  than quietly dropping the old (wrong) ruling. Two honest degradations,
  neither a fabrication: the coworker slot is omitted outright for an empty
  `coworkerId` (a solo agent's — and a lone coworker's — leads always are,
  and the coworkers feature is hidden for that session anyway), and while
  the roster is loading or has failed to load the footer shows only the
  created-at half (`Lead.createdAt`) — never a placeholder name, never a
  spinner standing in for one.
- **Two widget shapes each had two independent, near-identical
  implementations before this slice's integration pass** — `profile-buyer`/
  `profile-agent`'s Logout confirm dialog vs. `settings`'s own bespoke one
  (now `shared/widgets/sign_out_confirm.dart`'s `confirmSignOut`, a native
  `AlertDialog.adaptive` — the spec-correct chrome per §1's "native alert
  style" note on `delete-confirm`, which `settings`'s row text explicitly
  invokes), and `features/profile/`'s `ProfileRow` vs. `settings`'s private
  `_SettingsRow` (now `shared/widgets/list_row.dart`'s `ListRow`). A third
  near-duplicate — `features/auth/widgets/auth_form_widgets.dart`'s
  `AuthField`/`AuthVisibilityToggle`/`AuthPrimaryButton` vs.
  `edit_profile_screen.dart`'s private `_FormField`/`_VisibilityToggle`/
  `_PrimaryButton` — was deliberately **not** merged: `auth_form_widgets.dart`
  already documents why it stayed local (nothing outside `login`/`register`
  needed it at the time), and the two field widgets differ enough
  (`onChanged` required vs. optional, 52px vs. 56px buttons) that merging
  them safely is a task of its own rather than a mechanical promotion.
- **A second consolidation pass, once the Work/CRM tab (§21–§38) existed,
  found five more repeats and promoted them to `shared/widgets/`**: the
  13-way duplicated back-arrow app-bar row is now `nav_row.dart`'s `NavRow`
  (a `trailing: List<Widget>` slot covers `create-listing`'s close-icon shape
  and `leads-list`'s two extra actions — the latter's own toggle+add-lead
  pair, only shared by two screens, stayed local as
  `features/leads/widgets/leads_nav_actions.dart` rather than joining
  `NavRow` itself); the byte-identical form-field/visibility-toggle pair
  duplicated across `add-coworker`, `coworker-detail` and `edit-profile` is
  now `labelled_form_field.dart`/`visibility_toggle.dart`'s
  `LabelledFormField`/`VisibilityToggle`; `listing-editor`'s and
  `filter-sheet`'s identical field-label and choice-chip-group widgets are
  now `field_label.dart`'s `FieldLabel` and `choice_chip_group.dart`'s
  `ChoiceChipGroup<T>` (carrying Filter's `allowDeselect` and Listing's
  optional `label` as explicit parameters, not silent behaviour forks).
  `ListingTextField` and `LeadTextField` were deliberately **not** folded
  into `LabelledFormField` alongside them — both carry shape the shared
  widget doesn't (a required-asterisk label, `suffixText`, per-row padding
  tuned for how many fields each form packs in) and forcing one shape onto
  forms that were never the same would just move the duplication into
  `LabelledFormField`'s parameter list instead of removing it.
- **A third pass, made once the platform stand-ins above went real, found
  one more byte-identical repeat**: the dial-a-number-with-a-copy-fallback
  logic — request through `LinkLauncher.dial`, and on `false` copy the
  number and toast `"Couldn't open the dialer — phone number copied:
  $phone"` — existed independently, three separate times, in
  `profile-agent`'s phone row, `listing-detail`'s agent block, and
  `agent-profile`'s Call action, each written at its own call site with no
  visibility into the other two. Now `shared/widgets/dial_or_copy.dart`'s
  `dialOrCopyPhone`. `LinkLauncher.open`'s two other callers
  (`profile-buyer`'s "Register as Agent", `connected-accounts`' "Connect
  Instagram") were **not** folded in alongside it — each opens a different,
  hardcoded URL with its own toast copy naming what failed to open, so
  there is no shared logic to extract, only two call sites that happen to
  use the same seam.
- **A fourth pass, made while auditing this app's now-several server-paged
  lists for consistency, found one more near-duplicate.** `search`'s
  scroll-triggered infinite scroll (`search_results_list.dart`) had its own
  private `_LoadMoreFooter` — a spinner, or a tappable "Couldn't load more —
  Retry" row once a load-more call actually fails — and `my-listings`' own
  scroll-triggered list (`my_listings_list.dart`) had the same shape of
  problem (an invisible scroll-triggered fetch, with no way to tell the user
  anything went wrong) but no visible failure state at all: a failed
  load-more there just silently reset to a spinner-shaped sentinel with no
  explanation. Promoted to `shared/widgets/load_more_footer.dart`'s
  `LoadMoreFooter`, parameterized on its own `retryKey`/`spinnerKey` (each
  caller keeps its own existing widget-test keys rather than a shared
  literal forcing a rename), and `my-listings` gained the same
  `loadMoreFailed` state search already had (`MyListingsPageState
  .loadMoreFailed`) to actually drive it. **Deliberately not adopted by**
  `agent-profile`'s reviews list (`agent_reviews_section.dart`): that surface
  pages via an explicit "Show more reviews" tap, not a scroll listener, so
  the button reappearing after a failure already **is** the retry
  affordance — a second "failed" label under a button whose own
  reappearance already says "try again" would be noise, not clarity. Three
  server-paged surfaces now exist (`search`, `my-listings`, `agents`'
  reviews); each still has its own `PageState`-shaped Riverpod notifier
  (different item types, different fetch signatures, one genuinely different
  trigger mechanism) — only the failure-UI sentinel itself was duplicated
  code worth removing, not the paging state management around it.

## Maps

`map-view` and `listing-detail`'s Location preview both draw OpenStreetMap
tiles through `flutter_map` — the same source `apps/web`'s Leaflet map uses,
so neither surface needs an API key or a billing account.

Two things about that are load-bearing rather than incidental:

- **Attribution is a licence term.** `shared/map/map_attribution.dart` is
  rendered by every map surface. `flutter_map`'s own `SimpleAttributionWidget`
  is deliberately not used: it overflows a 390px phone by ~128px and credits
  the rendering library ahead of the data provider.
- **Tiles come from `mapTileLayerProvider`, never an inline `TileLayer`.**
  That is what lets widget tests substitute a plain coloured box; without it
  every map test would fire real requests at OSM's public servers from CI,
  which their usage policy forbids.

## On screenshots

Layout is verified with widget tests that pin `tester.view.physicalSize` to
360/390/430-wide phones and assert no `RenderFlex` overflow — see
`test/phone_width_overflow_test.dart` and the per-screen `layout holds at real
phone widths` groups. `leads/widgets/kanban_column_test.dart`'s own
`'layout holds at real phone widths under ru/uz'` group is the widest of
these: every `LeadStatus` column (5, `.unknown` excluded), at all 3 widths,
under both `ru` and `uz` (30 cases), each card carrying a resolved,
fairly-long-named coworker in its footer — the content most likely to
squeeze this layout. It replaced a
throwaway probe that only `print()`d on exception and never called `expect`,
so it could never actually fail CI regardless of what it rendered; the
load-bearing change was asserting on `tester.takeException()` instead of
just eyeballing console output. Browser screenshots of the web build are
**not** a
reliable substitute: the Flutter canvas does not consistently adopt Chrome's
`--window-size`, so a screenshot at a phone viewport shows clipping that is an
artifact of the canvas rather than a real layout fault.
