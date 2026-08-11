# Localization — conventions for the extraction passes

This is the rulebook the six extraction agents (one per group below) follow.
It exists so six people extracting strings independently produce ARB that
reads like one document, not six. Read this whole file before adding a
key — most of it is here because guessing wrong is expensive across six
concurrent PRs.

The toolchain itself (this file's siblings, `app.dart`'s wiring, the test
harness) is done and proven end to end on one real feature
(`features/settings/`, extracted in full — see `app_en.arb`/`app_uz.arb`/
`app_ru.arb` for the pattern in practice, and
`test/features/language/language_sheet_test.dart`'s
`'selecting a language changes the live app locale, no restart needed'` test
for proof the switch is live, no restart, no fake). Nothing below is
theoretical.

## File layout

```
l10n.yaml                        # flutter gen-l10n config — arb-dir, output-dir, etc.
lib/l10n/
  app_en.arb                     # template ARB — source of truth for keys + descriptions
  app_uz.arb                     # Uzbek (Latin script)
  app_ru.arb                     # Russian
  generated/                     # flutter gen-l10n output — COMMITTED, not gitignored
    app_localizations.dart       #   (see l10n.yaml's header comment for why: `pub get`
    app_localizations_en.dart    #   regenerates it, but committing means `flutter test`/
    app_localizations_uz.dart    #   `analyze` work for anyone who runs them without a
    app_localizations_ru.dart    #   `pub get` in between, and PRs show the real diff)
  README.md                      # this file
  GLOSSARY.md                    # agreed en/uz/ru domain-term renderings
```

**After editing any `.arb` file, run `flutter gen-l10n` (or `flutter pub
get`, which triggers it via `generate: true` in `pubspec.yaml`) and commit
the resulting `lib/l10n/generated/*` diff in the same PR.** `flutter
analyze`/`flutter test` will fail on stale generated code otherwise —
`AppLocalizations` won't declare the getter your new widget code calls.

## Key naming

**`<prefix><PascalCaseDescription>`** — lowerCamelCase overall: the group's
prefix (below) exactly as written, lowercase, then the rest of the name in
PascalCase with no separators. Keys are Dart getter/method names generated
by `flutter gen-l10n`, so they must be valid Dart identifiers — no dots, no
hyphens, no underscores.

Describe what the string **is**, not a running counter — `text1`/`msg2`/
`label3` are not acceptable names, and neither is copying the English words
verbatim into the key (translators change the words; the key should still
describe the role). Good and bad examples, from the worked example:

```
settingsScreenTitle              # good — role: nav-bar title on Settings
settingsLogoutRowTitle           # good — role: the Logout row's title
settingsNotificationsToggleLabel # good — role: semantics label, distinct from the row title
settingsText1                    # bad — no role
settingsLogout                   # bad — ambiguous: row title? confirm-dialog button? toast?
```

Keys are **stable** once translated — renaming a key means re-keying it in
all three ARB files, not just English. Don't rename a shipped key to fix a
typo in the *key name*; that's cosmetic and costs the uz/ru translations
nothing to keep. Do fix a typo in the *English value* — see "English is
authoritative" below.

## Placeholders

ARB placeholders use `{name}` in the message string and a matching entry
under `"@key": {"placeholders": {...}}` with at least a `type`. Worked
example, from `app_en.arb`:

```json
"settingsAboutRowSubtitle": "Version {version}",
"@settingsAboutRowSubtitle": {
  "description": "Subtitle under the About row on Settings: the app's version number.",
  "placeholders": {
    "version": { "type": "String", "example": "1.0.0" }
  }
}
```

generates `String settingsAboutRowSubtitle(String version)`. For a currency
or date/number placeholder, add `format` — e.g. a price would be
`{"type": "num", "format": "currency", "optionalParameters": {"symbol": "so'm"}}`
(La Casa prices are UZS integers, not currently formatted through `intl`'s
locale-aware currency machinery — `shared/formatters/formatters.dart` does
that today; a placeholder feeding it a pre-formatted `String` is equally
valid and is what `settingsAboutRowSubtitle` above does with `version`).
Placeholder **order** in the generated method follows first-occurrence order
in the message string, not the order keys appear in the `placeholders` map —
write the map in the same order as the message to avoid confusing whoever
reads the diff.

Two-placeholder worked example, also from `app_en.arb`:

```json
"settingsAboutToastMessage": "{appName} {version}",
"@settingsAboutToastMessage": {
  "description": "Brand name followed by version number, both passed through untranslated.",
  "placeholders": {
    "appName": { "type": "String", "example": "La Casa" },
    "version": { "type": "String", "example": "1.0.0" }
  }
}
```

Note `appName`/`version` are **not translated** — they're a proper noun and a
version string fed in from Dart constants (`data/app_version.dart`), not UI
wording. A placeholder is the correct move whenever part of a sentence is
data rather than words — including a brand name, a formatted number, or an
already-formatted date — even when that data happens to be static today.

## Plurals — read this before extracting any string with a count in it

**Any English string carrying a count must be an ICU `plural`, not string
concatenation.** This is the single most common way an i18n pass ships
silently broken: English only distinguishes singular/plural (`1 room` vs.
`3 rooms`), but Russian has four plural categories (`one`/`few`/`many`/
`other` — `1 комната` / `2 комнаты` / `5 комнат` / `1.5 комнаты`) and
Uzbek's rules differ again (Uzbek doesn't inflect nouns for plural count the
way Russian does — CLDR gives it just `other`, so a `plural` block still
degrades correctly, but Russian genuinely needs all four branches, and only
a native speaker can fill them in correctly). **A translator cannot fix a
string that was concatenated in Dart** — by the time it reaches them there
is one merged sentence, not a number and a noun they can separately
inflect.

ARB ICU plural syntax:

```json
"listingRoomsCount": "{count, plural, one{{count} room} other{{count} rooms}}",
"@listingRoomsCount": {
  "description": "Room count on a listing card/map pin.",
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

generates `String listingRoomsCount(int count)`; call it, don't build the
sentence yourself.

**The first plural to land is already identified and waiting:**
`lib/features/map_view/widgets/map_preview_card.dart:85` renders
`'$rooms room'` via plain interpolation — always the singular word
regardless of `rooms`' value (SCREENS.md/the mockup didn't spec pluralization
either, so this predates localization entirely). Whoever extracts
`map_view` (group 2, below) should turn this into `listingRoomsCount` (or an
equivalent `map`-prefixed key if the same count also needs a
non-`listing`-prefixed home) rather than copy the existing concatenation
into an ARB template string — an ARB value can itself be non-pluralized
`"{count} room"` and still be just as wrong; the `plural` block is the part
that actually fixes it. Grep for other `'$var room'`/`'$var results'`-shaped
interpolations before assuming this is the only one in your group.

## What NOT to extract

- **Enum wire values** — `"need_to_call_back"`, `"notRepaired"`, and every
  other snake_case value an `AppLanguage.fromWire`-shaped switch produces or
  consumes. These are protocol with the server, never shown to a user
  directly (a *display label* derived from one, like `LeadStatus.label`, is
  a different string and likely does need extraction — the wire value
  itself never does).
- **API field names / JSON keys.** Not user-facing at all.
- **Route paths** (`route_paths.dart`'s constants, anything passed to
  `context.go`/`context.push`). Not user-facing.
- **`ValueKey`/`Key` string values** (`ValueKey('settingsLanguageRow')` and
  similar). These exist for tests to find widgets, not for users to read —
  translating them would just break every test that keys off them for zero
  user benefit.
- **Log/debug strings.** Nothing a user sees.
- **Server-authored text — specifically `ApiErrorBody.message`
  (`lib/api/models/api_error_body.dart`).** This field is the literal string
  the server's own `res.status(...).json({ error: { code, message } })`
  sent — it is already the server's words, generated server-side (often
  interpolated with server-side data), and this client has no way to
  translate a string it only receives at runtime. **The rule: never wrap
  `error.message` in an ARB lookup; render it verbatim, exactly as every
  screen does today.** What *is* extractable is any client-authored copy
  *around* it — e.g. a static "Something went wrong:" prefix a screen adds
  before showing `error.message` — since that part is this client's own
  words. If a screen currently uses `ApiErrorCode` to choose between several
  client-authored fallback strings (rather than showing `error.message`
  directly), those fallback strings are ordinary extractable copy; only the
  raw passed-through `message` field itself is off limits.
- **`AppLanguage.label`** (`"En"`/`"Uz"`/`"Ru"`) — already covered by the
  wire-value rule above in spirit: SCREENS.md §3.20 quotes these three forms
  character for character regardless of the selected language (the point of
  the row is choosing a language by its own name, not a translated one), so
  `language_sheet.dart`/`settings_screen.dart`'s use of `.label` is correct
  as committed and is not a gap to close.

## `description` — required on every entry, no exceptions

Every key in `app_en.arb` needs an `"@key": {"description": "..."}` block.
The uz/ru translators (the next phase, one agent per group) work from the
English value **and** this description — "Save" as a button label and
"Save" as a verb mid-sentence translate differently in both Uzbek and
Russian, and a translator with only the bare string has no way to tell
which one they're looking at. Say **where it appears** (which screen/row/
control) and **what role it plays** (title vs. subtitle vs. semantics label
vs. button vs. toast vs. error), the way every entry in `app_en.arb`
already does. A description that just repeats the English value
(`"description": "Says Settings"`) is not acceptable — it must say where the
string appears in the widget tree, not the words it contains.

## English is authoritative, and byte-identical to what shipped

`app_en.arb`'s values must be **byte-identical** to the string literal you
are replacing — same words, same punctuation, same capitalisation, same
trailing space, same curly vs. straight apostrophe, same em dash vs. hyphen.
885 existing widget tests assert on this exact English text via
`find.text('...')`/`find.textContaining('...')`; if a test starts failing
after your extraction, the near-certain cause is a changed string, not a
wrong test. **Fix the ARB value back to match the original, don't edit the
test's expectation** — the one narrow exception is a test that was itself
asserting on now-intentionally-changed behaviour (as in
`language_sheet_test.dart`'s honesty-note test after this run removed that
note; see git history for that specific, deliberate case).

You are moving strings, not editing them. If a string looks wrong (a typo,
an awkward phrasing) while you're extracting it, **leave it exactly as
written and note it in your PR** — this pass is a mechanical relocation, not
a copy-editing pass, and "fixing" it silently both breaks a test and hides
a decision nobody signed off on.

## Test harness — how a test opts in

Every widget test that constructs its own `MaterialApp`/`MaterialApp.router`
(rather than pumping the real `App` widget from `app.dart`, which already
carries this) must include the generated delegate list, or any widget under
test that calls `AppLocalizations.of(context)` throws the moment it's
pumped. The fix is two named arguments plus one import — already applied to
every existing test-side `MaterialApp`/`MaterialApp.router` call as of this
run (65 call sites across 47 files):

```dart
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
// ...
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light(),
  // ...
),
```

(`MaterialApp.router(...)` takes the same two lines.)
`AppLocalizations.localizationsDelegates` already bundles
`GlobalMaterialLocalizations.delegate`/`GlobalCupertinoLocalizations.delegate`/
`GlobalWidgetsLocalizations.delegate` alongside the generated one — that's
generated code, not something to hand-roll — so this is genuinely the
entire fix, no per-file bespoke delegate list. **Any new test file you add
that builds its own `MaterialApp` needs these same two lines** — there is no
global default that supplies them automatically (Dart/Flutter has no hook
for that; see the git history on this file's sibling commit for why a
one-shared-constant approach was chosen over either hand-duplicating the
delegate list or a fragile binding-level monkeypatch). Copy the block above
verbatim rather than re-deriving it.

If a widget test doesn't build its own `MaterialApp` at all (e.g. it tests a
plain `StatelessWidget` in isolation with `Directionality`/`MediaQuery`
wrappers only), it doesn't need this — only add it once your widget under
test (or something it contains) actually calls `AppLocalizations.of`.

## Commands

```bash
flutter gen-l10n     # regenerate lib/l10n/generated/ after an ARB edit
flutter analyze      # must stay clean
flutter test         # must stay green — see the harness section above first
```

## Extraction groups

**Status: all six groups landed and merged into `app_{en,uz,ru}.arb` (683
keys, 100% translated in both uz and ru — no English-fallback keys).** The
per-group `lib/l10n/parts/*.json` fragments this table maps to are gone,
reconciled and folded into the three ARB files; this table is kept as the
historical map of which feature owns which prefix, useful when adding a new
string later. (688 at merge time; a later integration pass consolidated
seven duplicate `"Retry"` keys onto `sharedRetryLabel` and added two —
`languageSheetTitle`/`languageSheetCloseLabel` — for a genuine miss, see
`README.md`'s "Known gaps" for the full account.)

One prefix per feature directory; a group may own several prefixes. Prefixes
are chosen, not derived mechanically, so two features that share a word
(`listing` in both listing-detail and listing-editor) don't collide.

| Group | Feature directories (`lib/features/…`) | Prefixes |
|---|---|---|
| 1 — home/search/filter | `home`, `search`, `filter` | `home`, `search`, `filter` |
| 2 — listing-detail/gallery/map | `listing_detail`, `photo_gallery`, `map_view`, `contact` | `listing`, `gallery`, `map`, `contact` |
| 3 — listing-editor/publish/my-listings | `listing_editor` (create/edit-listing forms **and** the publish sheet/status screen that live under `listing_editor/widgets/`), `my_listings` | `listingEditor`, `publish`, `myListings` |
| 4 — leads/coworkers/work-dashboard/work-misc | `leads`, `coworkers`, `work_dashboard`, `work_misc` (three screens: notifications, messages, connected-accounts) | `leads`, `coworkers`, `dashboard`, `notifications`, `messages`, `connectedAccounts` |
| 5 — agents/reviews/profile/auth | `agents` (directory, profile, and its reviews sub-area), `profile`, `edit_profile`, `saved_listings`, `settings` (**done** — the worked example; re-verify rather than re-extract), `auth`, `onboarding`, `permissions` | `agents`, `reviews`, `profile`, `editProfile`, `savedListings`, `settings`, `auth`, `onboarding`, `permissions` |
| 6 — shared/navigation/formatters/theme | `lib/shared/` (widget kit — dialogs, empty states, list rows), `lib/navigation/` (tab labels, any nav-chrome copy) | `shared`, `nav` |

**Judgment calls made here, stated so you don't have to re-derive them:**
`contact` (its own `lib/features/contact/` directory, opened from both
`listing-detail` and `agent-profile`) is grouped with 2 rather than 5
because `listing-detail` is its more frequent caller and its copy ("Send a
message about this listing…") is listing-flavoured. `onboarding` and
`permissions-primer` are grouped with 5 rather than 6 because they're real
SCREENS.md screens with their own spec'd copy (§1/§2), not shared
infrastructure — they're folded into the auth/profile group because they
sit on the same pre-session path as `login`/`register`, not because they
share code with them. `lib/theme/` and `lib/shared/formatters/` are listed
in the group name but are not expected to contain extractable strings
(styling tokens and value-formatting functions, not copy) — group 6's actual
work is almost entirely `lib/shared/widgets/`; if a formatter does compose a
user-facing sentence (check `shared/formatters/formatters.dart` first),
extract it same as any other string, with a `shared`-prefixed key.
`language`'s own directory needs almost no extraction pass — most of its
surface is `AppLanguage.label`, which the "what not to extract" section
above covers — **except `language-sheet`'s own sheet title and close
button**, which are real SCREENS.md §3.20 copy (`'Sheet title "Language"'`)
and were missed by the original per-group table above; they're extracted as
`languageSheetTitle`/`languageSheetCloseLabel`, following the same
per-sheet-owned-Close-label pattern as `contactSheetCloseLabel` et al.
(found and fixed during the integration pass — see `README.md`'s "Known
gaps").
