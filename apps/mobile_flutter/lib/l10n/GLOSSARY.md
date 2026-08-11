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
| publish | e'lon qilish | опубликовать | The action of pushing a draft/listing to an external channel (Telegram/Instagram/OLX/Realting) — literally "make an announcement", which is also `e'lon`'s root (see "listing" above); not a false-friend collision, the two senses genuinely share a root in Uzbek the way "listing"/"to list" do in English. |
| review | sharh | отзыв | An agent review (rating + text) left by a buyer — not "review" in the sense of "review this PR"/"review my changes". |
| rating | reyting | рейтинг | The numeric `X/5` score; `sharh`/`отзыв` (review, above) is the accompanying written text — keep the two distinct even where English casually uses "review" to mean both. |

## Product name

**"La Casa" is never translated, in any language**, including inside a
placeholder value like `{appName}` (see `app_en.arb`'s
`settingsAboutToastMessage`) — it's a proper noun/brand name, not a
descriptive phrase.
