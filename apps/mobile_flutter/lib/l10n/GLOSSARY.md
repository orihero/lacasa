# Domain glossary — en / uz / ru

Fixes one rendering per domain term so six agents translating six different
groups don't independently invent six different words for "listing" or
"coworker". **Use these renderings whenever the term appears**, rather than
re-deciding per string — consistency here matters more than any single
string being marginally more idiomatic on its own.

If a term you need isn't listed, add it here (with the same reasoning
style: why this rendering, not a plausible alternative) rather than picking
one silently in your own group's ARB file — the next group needing the same
term should find it already decided.

## Register — decided once, applies everywhere

**Russian: formal `вы`, lowercase (not the letter-writing capitalized `Вы`).**
This is a consumer property app handling real transactions (contacting
agents, publishing listings, signing leases) in Uzbekistan's market, where
formal address is the deployed norm for this class of product (banking,
real estate, government-adjacent services) — informal `ты` would read as
presumptuous for a first-run stranger-to-business relationship, even though
"friendly `ты`" is common in some consumer apps elsewhere. Every Russian
string addressing the user directly (imperatives, "your X") uses this
register consistently.

**Uzbek: `siz` (the polite/plural second person), Latin script.** Uzbek's
formality axis is less sharply marked than Russian's, but `siz` is the
neutral, safe default matching the Russian formal choice above rather than
the more intimate `sen`. Latin script per `AppLanguage`'s own doc comment in
`data/app_language.dart` and `app.dart`'s locale-wiring comment — `Locale('uz')`
resolves to Latin by CLDR default; this is not a choice this glossary makes,
it's already fixed by the locale code itself, stated here so a translator
doesn't second-guess it.

## Terms

| English | Uzbek (Latin) | Russian | Notes |
|---|---|---|---|
| listing / ad | e'lon | объявление | SCREENS.md and every screen say "listing" in English; the server/API say "ad" (`AdPage`, `/ads`, `ApiErrorCode.adNotFound`) — both are the same domain object. **Translate the user-facing word ("listing"), not the API name** — uz/ru both render it as their one native "real-estate ad" word regardless of which English synonym a given string happens to use, since the distinction is English-internal (a UI-copy word vs. an API name) and doesn't exist in the other two languages. |
| property | ko'chmas mulk | недвижимость | Used sparingly in English copy (mostly "listing" is used instead) — when it does appear, this is the rendering, not a synonym of "listing" above. |
| agent / realtor | rieltor | риелтор | SCREENS.md uses "agent" in most copy but the domain concept is a licensed realtor (`UserRole.agent`, `realtor.kind` SOLO/TEAM on the server) — `rieltor`/`риелтор` (not `agent`/`агент`, which reads as a generic "agent" — insurance, travel — in both languages) is the precise, unambiguous term realtors themselves use in this market. |
| coworker | hamkasb | коллега | The server's own role name (`UserRole.coworker`) is an internal/team member added by an agent, not a peer real-estate agent at another firm — `hamkasb`/`коллега` ("colleague/teammate") captures that, rather than a literal "co-worker" calque. |
| lead | mijoz-so'rov | лид | `lid`/`лид` is standard CRM/sales terminology already in wide use in both languages for "a prospective client captured for follow-up" — a literal translation ("potential buyer") would lose the CRM-specific meaning (a lead is tracked through a pipeline with a status, not just "someone interested"). `mijoz-so'rov` (customer inquiry) is the fallback if a given string's context reads oddly with the loanword; prefer the loanword `lid` by default since it's what CRM users (agents/coworkers) already expect. |
| buyer | xaridor | покупатель | The `user` role (SCREENS.md's "buyer" persona) — a signed-in non-agent browsing/saving listings. |
| saved (listings) | saqlangan | сохранённые | Adjective describing the listings a buyer bookmarked (`saved-listings` screen) — not "safe" or "stored" in the data-persistence sense. |
| draft | qoralama | черновик | A listing not yet published to any channel. |
| active | faol | активный | A published, currently-live listing. |
| sold | sotilgan | продано | Terminal listing status. |
| rent | ijara | аренда | The "Rent" badge/filter — as a noun. When used as a verb ("for rent"), Uzbek stays `ijaraga` (dative case), Russian `в аренду`; note the case/preposition shift, don't just concatenate the noun form. |
| sale | sotuv | продажа | The "Sale" badge/filter — paired with "rent" above as the two listing types, not a discount/promotion sense of "sale". |
| price | narx | цена | |
| area | maydon | площадь | Square-meter floor area of a unit (`{area} m²` per SCREENS.md §"Sizes") — not "region"; see `district`/`region` below for the geographic terms this could otherwise collide with in translation. |
| room | xona | комната | Plural-sensitive — see `lib/l10n/README.md`'s "Plurals" section; Russian needs the full `one/few/many/other` ICU block (`1 комната` / `2 комнаты` / `5 комнат`), Uzbek does not inflect (`xona` stays `xona` regardless of count, per CLDR's `other`-only Uzbek plural rule) but still route it through the same `plural` ICU message for the count formatting/consistency, not a bespoke concatenation. |
| storey / floor | qavat | этаж | SCREENS.md's `{storey}/{floors}` (e.g. "3/9") is "unit's floor / building's total floors" — both English words describe the same Uzbek/Russian word `qavat`/`этаж`; the distinction (unit floor vs. building height) is carried by which half of the `{storey}/{floors}` pair a given number is, not by a different translated word. |
| district | tuman | район | The finer-grained of the two geographic terms (`{district}, {city}` per SCREENS.md's Listing Card). Do not conflate with `area` (floor area, above) — English "area" is never used for the geographic sense in this app's copy, but a translator seeing "district" and "area" adjacent in different strings should not merge them into one word. |
| region | viloyat | область | The coarser geographic term (`GET /regions`, the filter's region/district cascade) — a `viloyat`/`область` contains many `tuman`/`район`s. Tashkent city itself is handled by the server's own region data, not a special case this glossary needs to carve out. |
| publish | e'lon qilish | опубликовать | The action of pushing a draft/listing to an external channel (Telegram/Instagram/OLX) — literally "make an announcement", which is also `e'lon`'s root (see "listing" above); not a false-friend collision, the two senses genuinely share a root in Uzbek the way "listing"/"to list" do in English. |
| review | sharh | отзыв | An agent review (rating + text) left by a buyer — not "review" in the sense of "review this PR"/"review my changes". |
| rating | reyting | рейтинг | The numeric `X/5` score; `sharh`/`отзыв` (review, above) is the accompanying written text — keep the two distinct even where English casually uses "review" to mean both. |
| per month (price suffix) | /oyiga | /мес | The rental-period suffix glued straight onto a formatted price with no space (`sharedPricePerMonthSuffix`), e.g. `5 000 000 so'm/oyiga`. Both are the abbreviated classifieds form these markets already read as "per month" — Russian takes the standard clipped `/мес` (never the spelled-out `/в месяц`, and no full stop: `/мес.` collides visually with a decimal separator right after digits), Uzbek takes `/oyiga` (the dative "for a month", which is how the period is stated after a price; bare `/oy` reads as the noun "month", not a rate). Short by requirement, not by taste: this sits hard against a long digit group in a narrow card and a longer form wraps the price line. |
| no connection / offline | Internet aloqasi yo'q | Нет соединения | The read/write failure where the request never reached the server (`NetworkException`). One sentence app-wide — `"No connection. Check your network and try again."` — used by every form and, since `sharedOfflineErrorMessage`, by every *read* surface too. Deliberately **not** varied per screen: a dozen different phrasings for one condition is the exact defect that key exists to close. Do not translate it as "нет интернета"/"internet yo'q" ("no internet"), which claims to know the cause; the app only knows the server did not answer. |
| clear filters | Filtrlarni tozalash | Сбросить фильтры | The action on an empty state that exists only because filters excluded everything — it resets the *applied* filters, never the search query. Distinct from the filter sheet's own **Reset** (`filterResetButtonLabel` — uz `Qayta tiklash`, ru `Сбросить`), which clears the sheet's in-progress selection before Apply. Two different controls; keep the two renderings distinct so a user cannot read one as the other. |
| publish channel | kanal | канал | Instagram / Telegram / YouTube / OLX, plus the four display-only channels Threads / Facebook Marketplace / X / LinkedIn (ruling 7.13) — the external destinations a listing is cross-posted to. The channel *names* themselves are proper nouns and never translated (see `listingEditorChannel*Label`, identical in all three locales); only the surrounding word "channel" is. |
| published / failed / not published | E'lon qilindi / Xatolik / E'lon qilinmagan | Опубликовано / Ошибка / Не опубликовано | The three human states of one publish channel on a My Ads row's badge strip. Note these are the *translated* states; `publish-status`'s own pills deliberately print the raw wire enums (`PENDING`, `PUBLISHED`, `FAILED`) untranslated as a documented passthrough — the two must not be conflated, and fixing the passthrough is a spec question, not a translation one. |
| under review (application) | ko'rib chiqilmoqda | на рассмотрении | A realtor sign-up awaiting a human decision (`RealtorProfile.status == pending`). Uzbek uses the process ("is being reviewed"), Russian the state ("under consideration") — both are the standard formulation each language uses for a submitted application, rather than a literal calque of the other. |
| forgot password | Parolni unutdingizmi? | Забыли пароль? | Rendered as a question in both languages, matching the English link and every consumer sign-in flow these markets already read. Both address the user with the polite form fixed above. |
| sign in / log in | Kirish | Войти | One rendering for the action across every entry point — the button on login (`authLoginSubmitButtonLabel`), the per-screen CTAs, and the shared snackbar action (`sharedSignInActionLabel`). English uses "Sign in", "Sign In" and "Log out" interchangeably across screens; uz/ru do not follow that drift. As an invitation in a sentence rather than a button ("Sign in to …") it becomes uz `… uchun tizimga kiring` / ru `Войдите, чтобы …`, per the formal-register rule above. |

## Product name

**"La Casa" is never translated, in any language**, including inside a
placeholder value like `{appName}` (see `app_en.arb`'s
`settingsAboutToastMessage`) — it's a proper noun/brand name, not a
descriptive phrase.
