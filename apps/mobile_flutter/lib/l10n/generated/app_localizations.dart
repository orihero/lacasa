import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// Nav-bar title on the Settings screen (SCREENS.md §3.19).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// Semantics label (screen-reader only, no visible text) on the Settings screen's back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsNavBackLabel;

  /// Row title on Settings that opens the language-sheet bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageRowTitle;

  /// Agent-only row title on Settings; pushes the Connected Accounts screen.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get settingsConnectedAccountsRowTitle;

  /// Row title on Settings; tapping it shows the app name/version in a toast.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutRowTitle;

  /// Subtitle under the About row on Settings: the app's version number. {version} is the hand-transcribed value from data/app_version.dart, e.g. "1.0.0" — not user-facing wording, so it is passed through untranslated.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAboutRowSubtitle(String version);

  /// Snackbar shown when the About row on Settings is tapped: brand name followed by version number. Both placeholders are passed through untranslated — {appName} is the product's proper noun (see GLOSSARY.md) and {version} is a version string, neither is UI wording.
  ///
  /// In en, this message translates to:
  /// **'{appName} {version}'**
  String settingsAboutToastMessage(String appName, String version);

  /// Group-label heading above the Logout row on Settings, in the sense of "session/account", not "work session".
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get settingsSessionGroupLabel;

  /// Destructive (red) row title on Settings; signs the user out after a confirm dialog. Same word as a verb/action, not a noun.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogoutRowTitle;

  /// Transient subtitle on the Logout row on Settings while sign-out is in progress (present continuous — an in-progress action, not a completed one).
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get settingsLoggingOutLabel;

  /// Snackbar shown when sign-out itself succeeded but deleting the locally stored session token from the device keystore failed. Shown from two call sites with byte-identical copy: Settings' own _confirmLogout, and shared/widgets/sign_out_confirm.dart's confirmAndSignOut (used by profile-buyer/profile-agent's Logout rows) — kept as one key rather than two so the two copies of the same failure sentence can never drift apart in translation. "handing it on" means passing the physical device to someone else — a privacy warning, not a generic error.
  ///
  /// In en, this message translates to:
  /// **'Signed out, but the saved session couldn\'t be removed from this device. Sign out again, or remove the app, before handing it on.'**
  String get settingsSignOutTokenNotClearedMessage;

  /// Row title on Settings for the push-notifications toggle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsRowTitle;

  /// Honest-gap subtitle under the Notifications row on Settings: the toggle persists a real preference, but no push-notification infrastructure exists in this build yet. Do not soften or remove the honesty — see the file's own doc comment in settings_screen.dart.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet — push notifications aren\'t wired up in this build.'**
  String get settingsNotificationsRowSubtitle;

  /// Semantics label on the Notifications switch control itself on Settings, distinct from the row's own "Notifications" title label (a screen reader needs to tell the two apart).
  ///
  /// In en, this message translates to:
  /// **'Notifications toggle'**
  String get settingsNotificationsToggleLabel;

  /// Decorative location pill in the Home header row (home_header_row.dart) — no data-go/handler on it in the source markup, so tapping it does nothing.
  ///
  /// In en, this message translates to:
  /// **'Tashkent, Uzbekistan'**
  String get homeLocationPillLabel;

  /// Screen-reader semantics label on the Home header's notification bell icon, stating how many notifications are unread. The count is the real unread count from GET /notifications, which is agent/coworker-only, so it is 0 for a buyer or a signed-out visitor — the plural must read correctly for every value including zero.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Notifications, {count} unread} other{Notifications, {count} unread}}'**
  String homeNotificationsBellSemanticLabel(int count);

  /// Screen-reader semantics label on the Home header's search icon button, which navigates to the Search tab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchIconSemanticLabel;

  /// Heading text on the signed-out-only agent pitch banner on Home (agent_pitch_banner.dart).
  ///
  /// In en, this message translates to:
  /// **'Are you a real estate agent?'**
  String get homeAgentPitchHeading;

  /// Subtitle text on the signed-out-only agent pitch banner on Home, under the heading.
  ///
  /// In en, this message translates to:
  /// **'Manage your listings, leads and team in one app.'**
  String get homeAgentPitchSubtitle;

  /// Button label on the agent pitch banner on Home; pushes the register screen.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get homeAgentPitchButtonLabel;

  /// Chip label in Home's decorative category chip row (category_chip_row.dart) — selecting it is local UI state only and never fires a fetch.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeCategoryAllLabel;

  /// Chip label in Home's decorative category chip row — same non-interactive-fetch caveat as homeCategoryAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get homeCategoryApartmentLabel;

  /// Chip label in Home's decorative category chip row — same non-interactive-fetch caveat as homeCategoryAllLabel.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get homeCategoryHouseLabel;

  /// Chip label in Home's decorative category chip row — same non-interactive-fetch caveat as homeCategoryAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get homeCategoryOfficeLabel;

  /// Chip label in Home's decorative category chip row — same non-interactive-fetch caveat as homeCategoryAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get homeCategoryRetailLabel;

  /// Semantics label (screen-reader only) on a chip in Home's category chip row, now that tapping one navigates to search carrying an AdFilters payload rather than only repainting itself. {category} is the chip's own visible label — homeCategoryApartmentLabel and friends.
  ///
  /// In en, this message translates to:
  /// **'Show {category} listings'**
  String homeCategoryChipSemanticsLabel(String category);

  /// Section-header title above the Explore Nearby grid on Home (explore_nearby_grid.dart).
  ///
  /// In en, this message translates to:
  /// **'Explore Nearby'**
  String get homeExploreNearbySectionTitle;

  /// Section-header title above the Featured Listings rail on Home (featured_listings_rail.dart).
  ///
  /// In en, this message translates to:
  /// **'Featured Listings'**
  String get homeFeaturedListingsSectionTitle;

  /// Trailing link label on the Featured Listings section header on Home; navigates to the Search tab.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeFeaturedListingsViewAllLabel;

  /// Message on the compact retry card shown in the Featured Listings rail's position on Home when its fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load listings'**
  String get homeFeaturedListingsRetryMessage;

  /// Combined whole-Home-feed-empty message, rendered in the Featured Listings rail's position (below the chips) when the Home feed returns no ads at all.
  ///
  /// In en, this message translates to:
  /// **'No listings available yet.'**
  String get homeFeedEmptyMessage;

  /// Empty-state message in the Featured Listings rail's position on Home when the feed is empty *because* a category chip is active — distinct from homeFeedEmptyMessage, which claims the whole catalogue is empty and would be wrong here, since clearing the chip would bring listings back.
  ///
  /// In en, this message translates to:
  /// **'No listings in this category yet.'**
  String get homeFeedCategoryEmptyMessage;

  /// Two-line heading on the first hardcoded promo card in Home's promo carousel (promo_carousel.dart) — the literal newline reproduces the original two-element titleLines list joined for display.
  ///
  /// In en, this message translates to:
  /// **'One Post,\nEvery Channel'**
  String get homePromoOneTitle;

  /// Subtitle on the first promo card in Home's promo carousel. "Instagram"/"Telegram"/"YouTube" are product names and stay untranslated; only the surrounding words (e.g. "and") should change per language.
  ///
  /// In en, this message translates to:
  /// **'Instagram, Telegram and YouTube'**
  String get homePromoOneSubtitle;

  /// Two-line heading on the second hardcoded promo card in Home's promo carousel — same newline-joins-titleLines shape as homePromoOneTitle. "Yashnobod" is a Tashkent district name.
  ///
  /// In en, this message translates to:
  /// **'New in\nYashnobod'**
  String get homePromoTwoTitle;

  /// Subtitle on the second promo card in Home's promo carousel — hardcoded marketing copy with a fixed price, not driven by any provider or live listing data.
  ///
  /// In en, this message translates to:
  /// **'4-room new builds from \$95,000'**
  String get homePromoTwoSubtitle;

  /// Section-header title above the Top Agents rail on Home (top_agents_rail.dart).
  ///
  /// In en, this message translates to:
  /// **'Top Agents'**
  String get homeTopAgentsSectionTitle;

  /// Trailing link label on the Top Agents section header on Home; navigates to the Agents directory.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homeTopAgentsExploreLinkLabel;

  /// Message on the compact retry card shown in the Top Agents rail's position on Home when its fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load agents'**
  String get homeTopAgentsRetryMessage;

  /// Ad-count caption under an agent's avatar in the Top Agents rail on Home. The pre-existing Dart interpolation this replaces (`'${'{'}agent.adsCount{'}'} ads'`) always rendered the plural word regardless of count — a real, pre-existing bug this ICU plural corrects for the singular case per lib/l10n/README.md's plural-extraction guidance, without changing the wording any bundled fixture/test count (all >= 3) ever actually shows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} ad} other{{count} ads}}'**
  String homeAgentAdsCount(int count);

  /// Caption under an agent's avatar in Home's Top Agents rail, replacing the ad-count caption (homeAgentAdsCount) so the rail reports the endorsement its "Top Agents" heading implies rather than raw volume. {rating} is the server's one-decimal aggregate printed as-is (never rounded, never defaulted to 0) and {count} is how many reviews it averages; when ratingAverage is null the rail renders sharedNoReviewsYetLabel instead and never a zero-star row. The star glyph is punctuation, identical in all three locales.
  ///
  /// In en, this message translates to:
  /// **'★ {rating} ({count})'**
  String homeAgentRatingCaption(String rating, int count);

  /// Section-header title above the Top Districts rail on Home (top_districts_rail.dart).
  ///
  /// In en, this message translates to:
  /// **'Top Districts'**
  String get homeTopDistrictsSectionTitle;

  /// Trailing link label on the Top Districts section header on Home; navigates to the Search tab.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homeTopDistrictsExploreLinkLabel;

  /// Secondary line on a tile in Home's Top Districts rail: how many active listings the browse feed carries for that district, which is what "top" means on this rail (there is no other popularity signal in the system). Deliberately a new key rather than a reuse: homeAgentAdsCount says "ad" (the API's word, right under an agent's avatar) where this surface says "listing" (the buyer-facing word), and profileBuyerSavedListingsRowSubtitle carries a =0 branch this tile can never reach — a district with no listings is never in the rail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} listing} other{{count} listings}}'**
  String homeDistrictListingsCount(int count);

  /// Semantics hint (screen-reader only) on a tile in Home's Top Districts rail, stating what activating it does: tapping navigates to the Search tab carrying an AdFilters(district:) payload rather than running an unfiltered search. Announced after the tile's own merged label (district name + homeDistrictListingsCount). {district} is the tile's caption — the verbatim Ad.district string from the feed, not a translated name.
  ///
  /// In en, this message translates to:
  /// **'Show listings in {district}'**
  String homeDistrictTapSemanticsLabel(String district);

  /// Nav-bar title on the listing-search screen (search_screen.dart), the Search tab's root page.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchScreenTitle;

  /// Hint text inside the free-text search field on listing-search (search_bar_row.dart).
  ///
  /// In en, this message translates to:
  /// **'Search city, district, or title'**
  String get searchInputHint;

  /// Button beside the search field on listing-search; clears the field and drops focus (this is a tab root, not a pushed screen, so there is nothing to navigate back to).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get searchCancelButtonLabel;

  /// Label on the listing-search toolbar's button that opens filter-sheet (search_toolbar.dart).
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get searchFiltersButtonLabel;

  /// Chip label for one of listing-search's three inline Sort options (SearchSort.label, search_providers.dart) — threaded through AppLocalizations since the enum lives in a non-widget state file.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get searchSortHighestPriceLabel;

  /// Chip label for one of listing-search's three inline Sort options — same seam as searchSortHighestPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get searchSortLowestPriceLabel;

  /// Chip label for one of listing-search's three inline Sort options — same seam as searchSortHighestPriceLabel. Also the default-selected sort.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get searchSortNewestLabel;

  /// Full-width error message on listing-search's results list (search_results_list.dart) when the paged fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load listings.'**
  String get searchResultsRetryMessage;

  /// Full-width empty-state message on listing-search's results list when a search returns zero results (SCREENS.md §4, quoted verbatim). §1's convention (3) is not the governing rule here: it corrects the web app's misspelled "Not fount post" to "No listings found", which is what §10's Ads List empty state (agentsAdsGridEmptyMessage) shows — but §4 names its own screen-specific copy, and every other empty state in this file quotes its own section the same way. Deliberately a separate key from mapNoResultsMessage despite the identical English: map-view is the same search rendered on a map and must read the same today, but the two screens own their own copy and a future wording change to one must not silently move the other.
  ///
  /// In en, this message translates to:
  /// **'No listings match your search.'**
  String get searchResultsEmptyMessage;

  /// Empty-state message on listing-search when filters are applied, replacing searchResultsEmptyMessage so 'your filters are too narrow' is distinguishable from 'nothing matches this query'. Paired with the shared 'Clear filters' action.
  ///
  /// In en, this message translates to:
  /// **'No listings match your filters.'**
  String get searchResultsFilteredEmptyMessage;

  /// Section-header title above the Recent Searches chip row on listing-search (recent_searches_row.dart).
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get searchRecentSearchesSectionTitle;

  /// Trailing link on the Recent Searches section header; clears the persisted recent-searches list.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchRecentSearchesClearLabel;

  /// Header title on the filter-sheet bottom sheet (filter_sheet.dart), both the buyer and CRM variants.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterSheetTitle;

  /// Semantics label (screen-reader only, no visible text) on the filter-sheet header's round close ("X") button, following the same per-sheet-owned close-label pattern as contactSheetCloseLabel and reviewsSheetCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get filterSheetCloseLabel;

  /// Inline warning row on filter-sheet (buyer variant only) shown when the live result-count preview fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t calculate matching listings.'**
  String get filterCountErrorMessage;

  /// Footer button label on filter-sheet when no live count is shown — the CRM variant always, or the buyer variant while the count is loading/unavailable (filter_sheet_footer.dart).
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filterApplyButtonLabel;

  /// Footer button label on filter-sheet's buyer variant once the live buyer-facing result count has loaded. {count} is a bare numeral with no accompanying noun to inflect in any of the three languages (unlike homeAgentAdsCount's "ad(s)"), so this is a plain placeholder rather than an ICU plural block.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters ({count})'**
  String filterApplyButtonWithCountLabel(int count);

  /// Footer button on filter-sheet that clears every field to empty — a bare `const AdFilters()`, with no exceptions and nothing re-seeded. It does not restore SCREENS.md-stated defaults: the sheet no longer pre-selects Furniture/Repair on a fresh open, so 'reset' and 'fresh open' are now the same empty state.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterResetButtonLabel;

  /// Field label above filter-sheet's minimum-total-area number input (filter_area_section.dart). Note the period after "Min." — an abbreviation, byte-exact from the source string.
  ///
  /// In en, this message translates to:
  /// **'Min. total area'**
  String get filterAreaMinFieldLabel;

  /// Field label above filter-sheet's maximum-total-area number input. Unlike filterAreaMinFieldLabel, "Max" here has no trailing period — byte-exact from the source string, not a typo to fix.
  ///
  /// In en, this message translates to:
  /// **'Max total area'**
  String get filterAreaMaxFieldLabel;

  /// Field label above filter-sheet's Category (Rent/Sale) chip group (filter_category_type_section.dart).
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategoryFieldLabel;

  /// Field label above filter-sheet's Type (Residential/Nonresidential) chip group.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterTypeFieldLabel;

  /// Chip option label in filter-sheet's Category field (filter_options.dart's filterCategoryOptions).
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get filterCategoryRentOptionLabel;

  /// Chip option label in filter-sheet's Category field.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get filterCategorySaleOptionLabel;

  /// Chip option label in filter-sheet's Type field (filter_options.dart's filterTypeOptions).
  ///
  /// In en, this message translates to:
  /// **'Residential'**
  String get filterTypeResidentialOptionLabel;

  /// Chip option label in filter-sheet's Type field.
  ///
  /// In en, this message translates to:
  /// **'Nonresidential'**
  String get filterTypeNonresidentialOptionLabel;

  /// Field label above filter-sheet's City picker field (filter_city_district_section.dart).
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get filterCityFieldLabel;

  /// Header title of the City option-picker sheet opened by tapping the City field — a separate role from filterCityFieldLabel's static field label even though the text matches.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get filterCityPickerTitle;

  /// Placeholder text on the unset City field, and the label of the leading "clear" row inside its option-picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Any city'**
  String get filterCityAnyOptionLabel;

  /// Field label above filter-sheet's District picker field.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get filterDistrictFieldLabel;

  /// Header title of the District option-picker sheet — same field-label-vs-picker-title distinction as filterCityPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get filterDistrictPickerTitle;

  /// Placeholder text on the unset-but-enabled District field, and the label of the leading "clear" row inside its option-picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Any district'**
  String get filterDistrictAnyOptionLabel;

  /// Placeholder text on the District field while it is disabled because no City has been chosen yet.
  ///
  /// In en, this message translates to:
  /// **'Pick a city first'**
  String get filterDistrictPickCityFirstPlaceholder;

  /// Shared placeholder on filter-sheet's City and District fields while GET /regions is in flight.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get filterRegionsLoadingPlaceholder;

  /// Shared placeholder on filter-sheet's City and District fields when GET /regions fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get filterRegionsErrorPlaceholder;

  /// Field label above filter-sheet's Furniture chip group (filter_furniture_repair_section.dart).
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get filterFurnitureFieldLabel;

  /// Field label above filter-sheet's Repair chip group.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get filterRepairFieldLabel;

  /// Chip option label in filter-sheet's Furniture field (filter_options.dart's filterFurnitureOptions) — also this field's SCREENS.md-stated default. Lowercase "furniture" is byte-exact from the source string.
  ///
  /// In en, this message translates to:
  /// **'With furniture'**
  String get filterFurnitureWithOptionLabel;

  /// Chip option label in filter-sheet's Furniture field. Capitalised "Furniture" (unlike filterFurnitureWithOptionLabel's lowercase) is byte-exact from the source string, not a typo to fix.
  ///
  /// In en, this message translates to:
  /// **'Without Furniture'**
  String get filterFurnitureWithoutOptionLabel;

  /// Chip option label in filter-sheet's Repair field (filter_options.dart's filterRepairOptions) — also this field's SCREENS.md-stated default.
  ///
  /// In en, this message translates to:
  /// **'Not repaired'**
  String get filterRepairNotRepairedOptionLabel;

  /// Chip option label in filter-sheet's Repair field.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get filterRepairNormalOptionLabel;

  /// Chip option label in filter-sheet's Repair field.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get filterRepairGoodOptionLabel;

  /// Chip option label in filter-sheet's Repair field.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get filterRepairExcellentOptionLabel;

  /// Field label above filter-sheet's minimum-price chip group over the fixed price ladder (filter_price_section.dart).
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get filterPriceMinFieldLabel;

  /// Field label above filter-sheet's maximum-price chip group over the fixed price ladder.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get filterPriceMaxFieldLabel;

  /// Field label above filter-sheet's Rooms chip group (filter_rooms_section.dart), values 1-6.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get filterRoomsFieldLabel;

  /// Field label above filter-sheet's CRM-only Sort chip group (filter_sort_status_section.dart) — appended only when the sheet is opened via showCrmFilterSheet.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get filterSortFieldLabel;

  /// Field label above filter-sheet's CRM-only Status chip group — same CRM-only seam as filterSortFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatusFieldLabel;

  /// Chip option label in filter-sheet's CRM-only Sort field (filter_options.dart's filterCrmSortOptions) — also this field's default.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get filterSortNewestOptionLabel;

  /// Chip option label in filter-sheet's CRM-only Sort field.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get filterSortHighestPriceOptionLabel;

  /// Chip option label in filter-sheet's CRM-only Sort field.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get filterSortLowestPriceOptionLabel;

  /// Chip option label in filter-sheet's CRM-only Status field (filter_options.dart's filterCrmStatusOptions).
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterStatusActiveOptionLabel;

  /// Chip option label in filter-sheet's CRM-only Status field.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get filterStatusSoldOptionLabel;

  /// Chip option label in filter-sheet's CRM-only Status field.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get filterStatusDraftOptionLabel;

  /// Field label above filter-sheet's Storey number input (filter_storey_section.dart).
  ///
  /// In en, this message translates to:
  /// **'Storey'**
  String get filterStoreyFieldLabel;

  /// Heading of the Overview panel that opens listing-detail's body (the mockup's `.panel__h h3`), above the fact rail and the 3-up photo grid. The only new string that panel needs: its fact lines are built from the Sizes section's existing row labels (listingSizesRoomsLabel/FloorLabel/AreaLabel) and Formatters, so the panel and the Sizes pane cannot word the same figure two ways.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get listingOverviewSectionTitle;

  /// Section heading on listing-detail (SCREENS.md §3.7) above the ad's free-text description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get listingDescriptionSectionTitle;

  /// Section heading on listing-detail above the dynamic key/value chip list built from Ad.optionList.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get listingAdditionalInfoSectionTitle;

  /// Section heading on listing-detail above the Area/Rooms/Floor definition-list rows.
  ///
  /// In en, this message translates to:
  /// **'Sizes'**
  String get listingSizesSectionTitle;

  /// Section heading on listing-detail above the dynamic chip list built from Ad.nearPlacesList.
  ///
  /// In en, this message translates to:
  /// **'Nearby Places'**
  String get listingNearbyPlacesSectionTitle;

  /// Section heading on listing-detail above the map preview (or the honest no-pin state).
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get listingLocationSectionTitle;

  /// Terminal error message on listing-detail when the ad fetch resolves 404 (sold/removed listing). Distinct from listingLoadErrorMessage because "try again" is bad advice here; no Retry action is offered alongside it.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer available.\nIt may have been sold or removed.'**
  String get listingNotFoundMessage;

  /// Terminal error message on listing-detail when the ad fetch fails for any reason other than 404 (network/server error). Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this listing.'**
  String get listingLoadErrorMessage;

  /// Row title shown in place of the agent block on listing-detail when the agent fetch resolves null (deleted agent, a coworker id the agents endpoint refuses, or no network) — the agent block degrades on its own without taking the listing down.
  ///
  /// In en, this message translates to:
  /// **'Agent details unavailable'**
  String get listingAgentUnavailableLabel;

  /// Subtitle line under the agent's name in listing-detail's agent block: "Agent" role label, all-time ads-created count (pluralized on that count — the only part of this line that inflects), and deals-closed count (never pluralized in English, a fixed "N closed" tag rather than a noun-agreeing phrase — see the translation note on this key for how uz/ru render the fixed 'closed' word).
  ///
  /// In en, this message translates to:
  /// **'{adsCount, plural, one{Agent · {adsCount} listing · {dealsClosedCount} closed} other{Agent · {adsCount} listings · {dealsClosedCount} closed}}'**
  String listingAgentStatsLine(int adsCount, int dealsClosedCount);

  /// Semantics label on the phone-call icon button in listing-detail's agent block. {fullName} is the agent's name, passed through untranslated (a proper noun).
  ///
  /// In en, this message translates to:
  /// **'Call {fullName}'**
  String listingAgentCallSemanticsLabel(String fullName);

  /// Primary full-width CTA on listing-detail's floating bottom bar (SCREENS.md §3.7) — opens contact-sheet pre-filled with the listing.
  ///
  /// In en, this message translates to:
  /// **'Submit an application'**
  String get listingSubmitApplicationButtonLabel;

  /// Snackbar on listing-detail's "Save the Place" button when toggling the favourite fails (ApiException).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update favourites'**
  String get listingFavouriteUpdateErrorMessage;

  /// Label on listing-detail's secondary full-width button (SCREENS.md §3.7) when this listing is not yet saved — toggles to listingSavedButtonLabel once saved.
  ///
  /// In en, this message translates to:
  /// **'Save the Place'**
  String get listingSaveThePlaceButtonLabel;

  /// Label on listing-detail's secondary full-width button once this listing has been saved — the toggled state of listingSaveThePlaceButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get listingSavedButtonLabel;

  /// Semantics label on the round glass back button floating over listing-detail's hero photo.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get listingNavBackSemanticsLabel;

  /// Semantics label on the round glass share button floating over listing-detail's hero photo — opens the native OS share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get listingNavShareSemanticsLabel;

  /// Label on the small badge marking a video slide in listing-detail's hero carousel. Replaces the play glyph that read as 'this plays here' — the gallery cannot play it, so the badge names the medium instead of promising playback.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get listingHeroVideoBadgeLabel;

  /// Toast on listing-detail's share button when the OS share sheet was dismissed without a target and the app falls back to copying the listing's public link.
  ///
  /// In en, this message translates to:
  /// **'Link copied for sharing'**
  String get listingLinkCopiedToastMessage;

  /// Honest-gap message inside listing-detail's Location section when the ad carries no coordinates — this section renders even with no data, unlike the other optional sections.
  ///
  /// In en, this message translates to:
  /// **'No location provided for this listing.'**
  String get listingNoLocationMessage;

  /// Small label above the price figure in listing-detail's price-footer section (the one place price-per-m² also appears).
  ///
  /// In en, this message translates to:
  /// **'Asking price'**
  String get listingAskingPriceLabel;

  /// Row label in listing-detail's Sizes section for the floor area figure (e.g. "65 m²").
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get listingSizesAreaLabel;

  /// Row label in listing-detail's Sizes section for the room count figure.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get listingSizesRoomsLabel;

  /// Row label in listing-detail's Sizes section for the "{storey} / {floors}" figure.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get listingSizesFloorLabel;

  /// Row label in listing-detail's Sizes section for the property type (Residential/Nonresidential) — this section's own closing row, riding along with the size rows rather than always shown.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get listingSizesTypeLabel;

  /// Both: (1) the section heading on listing-detail above the 3D-tour banner, and (2) the nav-bar title on Tour3dViewScreen (the full-screen webview it pushes to) — same two words, same concept, in the same feature, so the key is shared rather than duplicated.
  ///
  /// In en, this message translates to:
  /// **'3D Tour'**
  String get listingTourSectionTitle;

  /// Semantics label on listing-detail's tappable 3D-tour banner.
  ///
  /// In en, this message translates to:
  /// **'View 3D Tour'**
  String get listingTourViewSemanticsLabel;

  /// Visible row title inside listing-detail's tappable 3D-tour banner (SCREENS.md §7's own wording).
  ///
  /// In en, this message translates to:
  /// **'Live 3D Tour'**
  String get listingTourBannerLabel;

  /// Terminal error message on Tour3dViewScreen when the ad's tour3dLink fails this screen's own scheme/host validation (not http/https, or unparsable). No Retry is offered alongside it — retrying a scheme that will never be valid isn't an honest offer.
  ///
  /// In en, this message translates to:
  /// **'This listing\'s 3D tour link isn\'t valid.'**
  String get listingTourInvalidLinkMessage;

  /// Terminal error message on Tour3dViewScreen when the (validated, well-formed) tour URL's main frame fails to load. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the 3D tour.'**
  String get listingTourLoadErrorMessage;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.type == residential.
  ///
  /// In en, this message translates to:
  /// **'Residential'**
  String get listingTypeResidentialLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.type == nonresidential.
  ///
  /// In en, this message translates to:
  /// **'Nonresidential'**
  String get listingTypeNonresidentialLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.category == sale — see GLOSSARY.md's "sale" entry.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get listingCategorySaleLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.category == rent — see GLOSSARY.md's "rent" entry.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get listingCategoryRentLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.repairment == notRepaired.
  ///
  /// In en, this message translates to:
  /// **'Not repaired'**
  String get listingRepairmentNotRepairedLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.repairment == normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get listingRepairmentNormalLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.repairment == good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get listingRepairmentGoodLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.repairment == excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get listingRepairmentExcellentLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.furniture == withFurniture. The lowercase "furniture" is the spec's own inconsistent capitalization, reproduced deliberately — see listingFurnitureWithoutLabel.
  ///
  /// In en, this message translates to:
  /// **'With furniture'**
  String get listingFurnitureWithLabel;

  /// Info-tag label on listing-detail (SCREENS.md §3.7) for Ad.furniture == withoutFurniture. Capital "Furniture" is SCREENS.md's own inconsistent capitalization (§3.7 writes exactly "With furniture"/"Without Furniture") and is reproduced character for character rather than silently tidied, so three implementations agree.
  ///
  /// In en, this message translates to:
  /// **'Without Furniture'**
  String get listingFurnitureWithoutLabel;

  /// Room count shown on a compact listing surface — currently map-view's pin-tap preview card (SCREENS.md §3.6's own un-pluralized "{rooms} room" spec wording; the ICU plural block is what actually makes it grammatical for a count other than 1, which the spec's literal wording doesn't handle). Named generically (listing-prefixed, not map-prefixed) since a room count belongs conceptually to a listing and other screens may need the same rendering later.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} room} other{{count} rooms}}'**
  String listingRoomsCount(int count);

  /// Centred message on photo-gallery (SCREENS.md §3.8) when the listing has no photos/video to show at all.
  ///
  /// In en, this message translates to:
  /// **'No photos available for this listing.'**
  String get galleryEmptyStateMessage;

  /// Message on a photo-gallery slide when that slide's media is a video — playback isn't implemented in this build (no video-player package installed), so this is an honest gap notice, not a load failure.
  ///
  /// In en, this message translates to:
  /// **'Video preview isn\'t available in the gallery yet.'**
  String get galleryVideoUnsupportedMessage;

  /// Message on a photo-gallery slide for a media type that is neither a photo nor a recognized video (the AdMediaType.unknown fallback).
  ///
  /// In en, this message translates to:
  /// **'This media type can\'t be previewed.'**
  String get galleryUnsupportedMediaMessage;

  /// Button label under the video placeholder in photo-gallery, opening the video's URL in the system browser/player. The interim exit from a slide the gallery itself cannot play.
  ///
  /// In en, this message translates to:
  /// **'Open video'**
  String get galleryOpenVideoExternallyLabel;

  /// Toast shown from photo-gallery when the system has nothing registered to open the video URL, so the app copied it to the clipboard instead — the same copy-and-toast fallback shape as the dialer and the Instagram sign-in link.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the video — link copied instead. Paste it into your browser to watch.'**
  String get galleryVideoLinkCopiedToastMessage;

  /// Semantics label on photo-gallery's page-dot row, read by a screen reader instead of the (visual-only) dots themselves. {current}/{total} are 1-indexed positions, not a pluralizing count — no noun in this string inflects on them.
  ///
  /// In en, this message translates to:
  /// **'Gallery position {current} of {total}'**
  String galleryPositionSemanticsLabel(int current, int total);

  /// Semantics label on each tile of photo-gallery's bottom thumbnail strip. {index}/{total} are 1-indexed positions, not a pluralizing count.
  ///
  /// In en, this message translates to:
  /// **'Photo {index} of {total}'**
  String galleryThumbnailSemanticsLabel(int index, int total);

  /// Tooltip (and accessible name) on photo-gallery's dismiss "X" button, top-left (SCREENS.md §3.8).
  ///
  /// In en, this message translates to:
  /// **'Close gallery'**
  String get galleryCloseTooltip;

  /// Semantics label on photo-gallery's top-right "{n}/{total}" counter chip. {label} is that already-formatted "n/total" string (GalleryFormatters.pageCounter) passed through untranslated — see this feature's report for why the bare digit/slash counter itself is not localized.
  ///
  /// In en, this message translates to:
  /// **'Photo {label}'**
  String galleryCounterSemanticsLabel(String label);

  /// Semantics label on map-view's round glass back button, top-left (SCREENS.md §3.6) — returns to listing-search.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mapNavBackSemanticsLabel;

  /// Header pill text on map-view (SCREENS.md §3.6: "Header 'Map'").
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitleLabel;

  /// Semantics label on map-view's list-icon toggle button, top-right (SCREENS.md §3.6) — same destination as the back button, both reaching for the same "back to the list" journey.
  ///
  /// In en, this message translates to:
  /// **'Show list'**
  String get mapShowListSemanticsLabel;

  /// Footer chip on map-view when some search results lack coordinates and could not be plotted (pinned count < total count) — the honest "n of m" form, e.g. "6 of 8 on the map".
  ///
  /// In en, this message translates to:
  /// **'{pinned} of {total} on the map'**
  String mapPinnedPartialCountLabel(int pinned, int total);

  /// Honesty caption above map-view's Filters button when the search has more pages than the map has plotted: says how many of the matched listings are actually on screen. Pairs with sharedLoadMoreLabel as the way to plot the rest.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Showing the first {count} match} other{Showing the first {count} matches}}'**
  String mapPartialResultsLabel(int count);

  /// Spinner chip above map-view's Filters button while a filter change's re-fetch is still in flight. The map deliberately keeps drawing the previous filter set's pins during that window (blanking a map the user has panned and zoomed would throw their orientation away), so this is the only thing on screen saying those pins are not the answer yet.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get mapUpdatingResultsLabel;

  /// Floating button label on map-view (SCREENS.md §3.6) — opens filter-sheet.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get mapFiltersButtonLabel;

  /// Centred card message on map-view when the search returned results but none carried coordinates to plot — distinct from mapNoResultsMessage (the search itself returned nothing).
  ///
  /// In en, this message translates to:
  /// **'None of these listings have a saved location.'**
  String get mapNoLocationResultsMessage;

  /// Centred card message on map-view when the search returned no results at all — distinct from mapNoLocationResultsMessage (results exist but none have coordinates).
  ///
  /// In en, this message translates to:
  /// **'No listings match your search.'**
  String get mapNoResultsMessage;

  /// Semantics label on a map-view cluster badge (overlapping pins merged by flutter_map_marker_cluster) — names the count and the tap action for a screen reader.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} listing here, tap to zoom in} other{{count} listings here, tap to zoom in}}'**
  String mapClusterSemanticsLabel(int count);

  /// Semantics label on a single (non-clustered) map-view pin — the listing's title and formatted price, both data rather than UI wording, passed through untranslated; only the comma-separated structure is this string's own.
  ///
  /// In en, this message translates to:
  /// **'{title}, {price}'**
  String mapPinSemanticsLabel(String title, String price);

  /// Semantics label on saved-listings' back button (SCREENS.md §3.17).
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get savedListingsNavBackSemanticsLabel;

  /// Header title on saved-listings (SCREENS.md §3.17).
  ///
  /// In en, this message translates to:
  /// **'Saved Listings'**
  String get savedListingsScreenTitle;

  /// Message on saved-listings' sign-in prompt, shown when a signed-out session deep-links into this screen — SCREENS.md defines no string for this exact case, so this is written to match the app's voice rather than quoted from §3.17 (see saved_listings_screen.dart's doc comment).
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your saved listings.'**
  String get savedListingsSignInPromptMessage;

  /// Button on saved-listings' sign-in prompt — pushes the login screen.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get savedListingsSignInButtonLabel;

  /// Error message on saved-listings when fetching the saved-ads list fails. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your saved listings'**
  String get savedListingsLoadErrorMessage;

  /// Empty-state message on saved-listings when the signed-in user has saved nothing — SCREENS.md §3.17's own copy, quoted verbatim.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any listings yet.'**
  String get savedListingsEmptyStateMessage;

  /// Cancel button shared by the three AlertDialog.adaptive confirms in shared/widgets/: delete-confirm (SCREENS.md §38), discard-changes-confirm (§5), and sign-out-confirm (Logout). Same role in all three — dismiss without taking the destructive action — so one key serves all three call sites.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sharedConfirmDialogCancelLabel;

  /// Title of the shared delete-confirm alert (SCREENS.md §38: 'Delete listing?' / 'Delete lead?' / 'Delete coworker?'), built from {subject}. The caller passes {subject} as a noun already localized to the app's current language (e.g. the listing/lead/coworker word from GLOSSARY.md) — this template only supplies the surrounding question, since the composing widget (shared/widgets/delete_confirm.dart) itself has no way to know which flow called it.
  ///
  /// In en, this message translates to:
  /// **'Delete {subject}?'**
  String sharedDeleteConfirmTitle(String subject);

  /// Body text under the title on the shared delete-confirm alert (SCREENS.md §38) — the same sentence regardless of what is being deleted.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get sharedDeleteConfirmBody;

  /// Destructive (red) confirm button on the shared delete-confirm alert. Same word as a verb/action, not a noun.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sharedDeleteConfirmDeleteLabel;

  /// Title of the shared discard-changes alert (SCREENS.md §5) shown before dismissing a form with unsaved state (create/edit-listing, edit-profile, create-lead, add-coworker, coworker-detail).
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get sharedDiscardChangesTitle;

  /// Body text under the title on the shared discard-changes alert.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. If you leave now, they won\'t be saved.'**
  String get sharedDiscardChangesBody;

  /// Destructive (red) confirm button on the shared discard-changes alert — proceeds without saving.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get sharedDiscardChangesDiscardLabel;

  /// Title of the shared sign-out confirm alert (shared/widgets/sign_out_confirm.dart), used by profile-buyer's and profile-agent's Logout rows.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get sharedSignOutTitle;

  /// Body text under the title on the shared sign-out confirm alert.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your account.'**
  String get sharedSignOutBody;

  /// Destructive (red) confirm button on the shared sign-out confirm alert. Same word as a verb/action, not a noun.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get sharedSignOutConfirmLabel;

  /// Shown by RatingStars (shared/widgets/rating_stars.dart) in place of the star row/count whenever an agent's rating average is null (a SQL aggregate over zero reviews) — never a zero-star row, see that file's own doc comment for why null and 0.0 are different facts.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get sharedNoReviewsYetLabel;

  /// The star row's trailing label on RatingStars (shared/widgets/rating_stars.dart), quoting SCREENS.md §3.9's 'Review: {rating}/5' exactly. {rating} arrives pre-formatted to one decimal place. No review count: neither the spec nor any `.acard__r` string in the mockup carries a parenthetical, and the count already has its own place in the surrounding line.
  ///
  /// In en, this message translates to:
  /// **'Review: {rating}/5'**
  String sharedRatingLabel(String rating);

  /// Fallback StatusPill label (shared/widgets/status_pill.dart) shown when an AdStage/LeadStatus/PublishStatus value from the server is not one this build recognizes yet. Reused across all three status vocabularies rather than three separate keys, since the role — "this build doesn't know what to call it" — is identical in all three.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sharedStatusUnknownLabel;

  /// AdStagePill label (shared/widgets/status_pill.dart) for a published, currently-live listing.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sharedAdStageActiveLabel;

  /// AdStagePill label (shared/widgets/status_pill.dart) for a listing marked sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sharedAdStageSoldLabel;

  /// AdStagePill label (shared/widgets/status_pill.dart) for a listing not yet published to any channel.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get sharedAdStageDraftLabel;

  /// LeadStatusPill label (shared/widgets/status_pill.dart), SCREENS.md §30's Kanban column for a lead not yet worked.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get sharedLeadStatusNewLabel;

  /// LeadStatusPill label (shared/widgets/status_pill.dart), SCREENS.md §30's exact display string — note the title case, distinct from console's own relabeled 'Could not connect'.
  ///
  /// In en, this message translates to:
  /// **'Could Not Connect'**
  String get sharedLeadStatusCouldNotConnectLabel;

  /// LeadStatusPill label (shared/widgets/status_pill.dart), SCREENS.md §30's exact display string (title case).
  ///
  /// In en, this message translates to:
  /// **'Need To Call Back'**
  String get sharedLeadStatusNeedToCallBackLabel;

  /// LeadStatusPill label (shared/widgets/status_pill.dart), SCREENS.md §30's Kanban column for a lead that declined.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get sharedLeadStatusRejectedLabel;

  /// LeadStatusPill label (shared/widgets/status_pill.dart), SCREENS.md §30's Kanban column for a lead that converted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get sharedLeadStatusAcceptedLabel;

  /// PublishStatusPill label (shared/widgets/status_pill.dart). SCREENS.md §29 and the mockup both quote the raw wire enum in caps, so this string is the wire value itself and is NOT translated in uz/ru.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get sharedPublishStatusPendingLabel;

  /// PublishStatusPill label (shared/widgets/status_pill.dart). SCREENS.md §29 and the mockup both quote the raw wire enum in caps, so this string is the wire value itself and is NOT translated in uz/ru.
  ///
  /// In en, this message translates to:
  /// **'DRAFTED_AWAITING_REVIEW'**
  String get sharedPublishStatusAwaitingReviewLabel;

  /// PublishStatusPill label (shared/widgets/status_pill.dart). SCREENS.md §29 and the mockup both quote the raw wire enum in caps, so this string is the wire value itself and is NOT translated in uz/ru.
  ///
  /// In en, this message translates to:
  /// **'PUBLISHED'**
  String get sharedPublishStatusPublishedLabel;

  /// PublishStatusPill label (shared/widgets/status_pill.dart). SCREENS.md §29 and the mockup both quote the raw wire enum in caps, so this string is the wire value itself and is NOT translated in uz/ru.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get sharedPublishStatusFailedLabel;

  /// Fallback error-toast message (shared/widgets/toast.dart's LaCasaToast._defaultErrorMessage) shown when LaCasaToast.run's action throws something other than an ApiException (which instead shows that exception's own server-authored message verbatim, never wrapped in an ARB lookup — see lib/l10n/README.md's ApiErrorBody.message rule).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get sharedGenericErrorMessage;

  /// The one message every *read* surface shows in place of its own per-screen 'Couldn't load X' string when the failure was a NetworkException. Rendered by `shared/widgets/read_error.dart`'s describeReadError into FullWidthState/RailRetryCard on search, my-listings, coworkers, notifications, saved-listings, the agents directory, publish-status and both leads views — deliberately the same wording every form already uses, so one connectivity failure reads as one fact rather than a dozen unrelated ones.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get sharedOfflineErrorMessage;

  /// Semantics label on VisibilityToggle (shared/widgets/visibility_toggle.dart) when the password field is currently obscured — tapping it will reveal the text.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get sharedShowPasswordLabel;

  /// Semantics label on VisibilityToggle (shared/widgets/visibility_toggle.dart) when the password field is currently visible — tapping it will re-obscure the text.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get sharedHidePasswordLabel;

  /// Default semantics label on AvatarUploadControl (shared/widgets/avatar_upload_control.dart) and the title of the camera/gallery sheet it opens — used by edit-profile, coworker-detail and add-coworker's avatar controls.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get sharedChangePhotoLabel;

  /// Semantics label on the close (X) icon in the camera/gallery choice sheet (shared/widgets/media_source_sheet.dart).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sharedMediaSourceCloseLabel;

  /// Row label in the camera/gallery choice sheet (shared/widgets/media_source_sheet.dart) for picking a photo from the device camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get sharedMediaSourceCameraLabel;

  /// Row label in the camera/gallery choice sheet (shared/widgets/media_source_sheet.dart) for picking a photo from the device's photo library.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get sharedMediaSourceGalleryLabel;

  /// Semantics label (screen-reader only, no visible text) on the back arrow of the shared NavRow header (shared/widgets/nav_row.dart), used by every Work-tab screen's header. Distinct from settingsNavBackLabel, which is Settings' own separate back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get sharedNavRowBackLabel;

  /// Semantics label (screen-reader only, no visible text) on the close (X) icon of the shared NavRow header (shared/widgets/nav_row.dart) — the 'close' layout used by Create Listing's first step.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sharedNavRowCloseLabel;

  /// Success toast shown by dialOrCopyPhone (shared/widgets/dial_or_copy.dart) when no dialer answered the tel: intent, so the number was copied to the clipboard instead. {phone} is the raw phone number, not translatable data.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the dialer — phone number copied: {phone}'**
  String sharedDialFallbackToastMessage(String phone);

  /// Snackbar shown by FavouriteButton (shared/widgets/favourite_button.dart) when toggling a listing's favourite state fails with an ApiException.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update favourites'**
  String get sharedFavouriteUpdateFailedMessage;

  /// Semantics label and tooltip on FavouriteButton (shared/widgets/favourite_button.dart) and listing-detail's bottom-bar heart while the listing is NOT saved — the state the tap would change it out of. Its sibling sharedFavouriteRemoveSemanticsLabel covers the saved state.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get sharedFavouriteAddSemanticsLabel;

  /// Semantics label and tooltip on FavouriteButton (shared/widgets/favourite_button.dart) and listing-detail's bottom-bar heart while the listing IS saved. Paired with sharedFavouriteAddSemanticsLabel, which covers the unsaved state.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get sharedFavouriteRemoveSemanticsLabel;

  /// Snackbar shown by FavouriteButton (shared/widgets/favourite_button.dart) when a SIGNED-OUT session taps the heart on a listing card. Replaces sharedFavouriteUpdateFailedMessage on that path, which was a lie: nothing was wrong with the network or the server, the request simply requires a session. Worded as an invitation, not an error — the same voice as profileSignedOutPromptMessage (SCREENS.md §3.14), narrowed to the one thing the tap was actually trying to do. Pairs with sharedSignInActionLabel as the snackbar's action button.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save listings'**
  String get sharedSignInToSaveMessage;

  /// SnackBarAction label on the shared signed-out prompts raised from lib/shared/widgets/ (today: FavouriteButton's sharedSignInToSaveMessage snackbar); pushes the login screen. Shared-group sibling of the per-screen savedListingsSignInButtonLabel/reviewsSectionSignInButtonLabel/profileSignedOutSignInButtonLabel/coworkersSignInActionLabel, which each stay screen-owned; a shared widget needs a shared-prefixed key rather than borrowing another feature's. Wording matches authLoginSubmitButtonLabel's sentence case because this is a snackbar action, not a title-cased screen CTA.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sharedSignInActionLabel;

  /// Action-pill label on a FullWidthState empty state that exists only because filters excluded everything — listing-search's results list and My Ads. Tapping it resets the applied filters (not the search query, which is its own visible affordance). Distinct from filter-sheet's own 'Reset' button, which clears the sheet's in-progress selection.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get sharedClearFiltersActionLabel;

  /// Tappable retry label on LoadMoreFooter (shared/widgets/load_more_footer.dart) — the trailing sentinel row on a server-paged infinite-scroll list (search, my-listings, agents' review list) when the next page fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more — Retry'**
  String get sharedLoadMoreFailedLabel;

  /// Label on an explicit fetch-the-next-page control, for a surface with no scroll to trigger the automatic loader — today map-view's 'Showing the first N matches' strip. The paged lists auto-load and use sharedLoadMoreLoadingLabel instead.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get sharedLoadMoreLabel;

  /// Tappable retry label inside RailRetryCard (shared/widgets/list_states.dart) — a compact, scoped failure card for a secondary/scoped list section.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get sharedRetryLabel;

  /// Category badge overlaid on a listing photo in FullListingCard (shared/widgets/full_listing_card.dart) when the ad's category is 'sale' — see GLOSSARY.md's "sale" entry for the term rendering.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sharedListingCardSaleBadgeLabel;

  /// Category badge overlaid on a listing photo in FullListingCard (shared/widgets/full_listing_card.dart) when the ad's category is 'rent' — see GLOSSARY.md's "rent" entry for the term rendering.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get sharedListingCardRentBadgeLabel;

  /// Room count as rendered by Formatters.rooms/statLine (shared/formatters/formatters.dart) whenever a BuildContext/AppLocalizations is available (FullListingCard, CompactListingCard) — SCREENS.md's own '{rooms} room' template pluralized ('1 room' / '3 rooms'), same divergence from the spec's literal singular-only text that the original unlocalized helper already made (see that method's doc comment). Same shape as listingRoomsCount (map-view's own instance of this identical problem) but kept as a separate key since the two are extracted by different agents/prefixes and formatting is applied at a different call site; Formatters.rooms/statLine keep an unlocalized fallback path for the many call sites elsewhere in the app that do not yet pass a BuildContext through — see this run's report for the cross-group signature-change constraint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} room} other{{count} rooms}}'**
  String sharedRoomsCount(int count);

  /// Rental-period suffix appended directly onto an already-formatted price, with no space, wherever a rent-category ad's price is rendered — e.g. "5 000 000 so'm/month". The three sites that still hardcode the English "/month" and should read this key instead are shared/formatters/formatters.dart:73 (Formatters.price), shared/widgets/price_pill.dart:80 and shared/widgets/row_listing_card.dart:216. Kept as its own key rather than folded into the price template because the amount and its currency are pre-formatted data (see listingEditorPriceValuePreview) while this is the one translatable word in the string. Note the constraint documented at formatters.dart:55-66: many Formatters.price call sites (map-view, listing-detail's hero/footer/share text) have no BuildContext, so its AppLocalizations argument is optional and this key can only be routed in where a context is actually available — the widget sites can read it directly. Deliberately the abbreviated form each language uses in classifieds (ru "/мес", uz "/oyiga"): it sits hard against a long digit group in a narrow card, so a spelled-out month noun would wrap the price line.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get sharedPricePerMonthSuffix;

  /// Bottom tab bar label/semantics label for the Home branch (lib/navigation/shell/glass_tab_bar.dart), always visible.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navTabHomeLabel;

  /// Bottom tab bar label/semantics label for the Search branch (lib/navigation/shell/glass_tab_bar.dart), always visible.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navTabSearchLabel;

  /// Name of the agent-side workspace as a whole. No longer a tab label — the agent shell has five tabs of its own (navTabDashboardLabel and friends) — but still the word register's realtor copy uses for the thing an approved realtor gets.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get navTabWorkLabel;

  /// Agent shell tab bar label/semantics label for branch 0, the dashboard (lib/navigation/shell/glass_tab_bar.dart). Deliberately the same word as dashboardScreenHeaderTitle, the header of the screen it opens, rather than a second name for one screen.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navTabDashboardLabel;

  /// Agent shell tab bar label/semantics label for branch 1, my-listings (lib/navigation/shell/glass_tab_bar.dart). Shorter than dashboardWorkspaceMyAdsRowTitle where the two differ — a tab label has less room than a list row.
  ///
  /// In en, this message translates to:
  /// **'My Ads'**
  String get navTabMyAdsLabel;

  /// Agent shell tab bar label/semantics label for branch 2, the leads list (lib/navigation/shell/glass_tab_bar.dart).
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get navTabLeadsLabel;

  /// Agent shell tab bar label/semantics label for branch 3, the coworkers list (lib/navigation/shell/glass_tab_bar.dart). Uses the app's established 'coworker' vocabulary (dashboardWorkspaceCoworkersRowTitle, coworkers-list) rather than introducing 'team' as a second word for the same people.
  ///
  /// In en, this message translates to:
  /// **'Coworkers'**
  String get navTabCoworkersLabel;

  /// Bottom tab bar label/semantics label for the Agents branch (lib/navigation/shell/glass_tab_bar.dart), always visible.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get navTabAgentsLabel;

  /// Bottom tab bar label/semantics label for the Profile branch (lib/navigation/shell/glass_tab_bar.dart), always visible.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navTabProfileLabel;

  /// Header on the permissions-primer screen (SCREENS.md §3.2), quoted verbatim including its ellipsis character.
  ///
  /// In en, this message translates to:
  /// **'Allow La Casa to…'**
  String get permissionsHeaderTitle;

  /// Row title on the permissions-primer screen (SCREENS.md §3.2) for the camera/photo-library permission.
  ///
  /// In en, this message translates to:
  /// **'Camera & Photos'**
  String get permissionsCameraRowTitle;

  /// Row body text on the permissions-primer screen (SCREENS.md §3.2) explaining why the camera/photo-library permission is being asked for.
  ///
  /// In en, this message translates to:
  /// **'To add photos to your listings and profile avatar'**
  String get permissionsCameraRowBody;

  /// Row title on the permissions-primer screen (SCREENS.md §3.2) for the notifications permission.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionsNotificationsRowTitle;

  /// Row body text on the permissions-primer screen (SCREENS.md §3.2) explaining why the notifications permission is being asked for.
  ///
  /// In en, this message translates to:
  /// **'To alert you about new leads and publish status.'**
  String get permissionsNotificationsRowBody;

  /// Secondary footer button on the permissions-primer screen (SCREENS.md §3.2) — dismisses without asking for anything.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permissionsNotNowButtonLabel;

  /// Primary footer button on the permissions-primer screen (SCREENS.md §3.2) — returns to the screen that triggered this one.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get permissionsContinueButtonLabel;

  /// Per-row button on the permissions-primer screen (SCREENS.md §3.2) that raises the real OS permission prompt, shown before either row has been asked about yet.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permissionsAllowButtonLabel;

  /// Per-row status line on the permissions-primer screen once a permission was granted in full (PermissionOutcome.granted).
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get permissionsAllowedStatusLabel;

  /// Per-row status line on the permissions-primer screen for iOS's limited-photo-access grant (PermissionOutcome.limited). Tapping opens system settings, the only lever available to widen the grant.
  ///
  /// In en, this message translates to:
  /// **'Allowed — limited to selected photos. Tap to choose more.'**
  String get permissionsLimitedStatusLabel;

  /// Per-row status line on the permissions-primer screen when a permission was denied but the OS can still raise another prompt later (PermissionOutcome.denied).
  ///
  /// In en, this message translates to:
  /// **'Not allowed — you can change this in system settings'**
  String get permissionsDeniedStatusLabel;

  /// Per-row status line on the permissions-primer screen when the OS will not raise another in-app prompt at all (PermissionOutcome.permanentlyDenied) — Settings is the only path left, distinct from the plain-denied wording above.
  ///
  /// In en, this message translates to:
  /// **'Not allowed — tap to open system settings'**
  String get permissionsPermanentlyDeniedStatusLabel;

  /// Per-row status line on the permissions-primer screen when this build has no backend to ask at all (PermissionOutcome.unavailable, e.g. Notifications with no push infrastructure wired up).
  ///
  /// In en, this message translates to:
  /// **'Not available in this build yet'**
  String get permissionsUnavailableStatusLabel;

  /// Top-right button on every onboarding slide (SCREENS.md §3.1) — exits the carousel and marks it seen.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkipButtonLabel;

  /// Primary button on the first two onboarding slides (SCREENS.md §3.1 names a button only on the final slide; the earlier slides carry this one so a user who never tries a swipe is not stranded — see onboarding_screen.dart's doc comment).
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNextButtonLabel;

  /// Primary button on the final onboarding slide only (SCREENS.md §3.1) — exits the carousel and marks it seen.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStartedButtonLabel;

  /// Title of onboarding slide 1 of 3 (SCREENS.md §3.1, quoted verbatim).
  ///
  /// In en, this message translates to:
  /// **'Manage every listing in one place'**
  String get onboardingSlideOneTitle;

  /// Body text of onboarding slide 1 of 3 (SCREENS.md §3.1, quoted verbatim).
  ///
  /// In en, this message translates to:
  /// **'Keep all your listings organized and easy to access, all in one app.'**
  String get onboardingSlideOneBody;

  /// Title of onboarding slide 2 of 3 (SCREENS.md §3.1, quoted verbatim).
  ///
  /// In en, this message translates to:
  /// **'Share to every channel at once'**
  String get onboardingSlideTwoTitle;

  /// Body text of onboarding slide 2 of 3 (SCREENS.md §3.1, quoted verbatim).
  ///
  /// In en, this message translates to:
  /// **'Publish to Instagram, Telegram and more without leaving the app.'**
  String get onboardingSlideTwoBody;

  /// Title of onboarding slide 3 of 3 (SCREENS.md §3.1, quoted verbatim).
  ///
  /// In en, this message translates to:
  /// **'Track leads from first contact to close'**
  String get onboardingSlideThreeTitle;

  /// Body text of onboarding slide 3 of 3 (SCREENS.md §3.1, quoted verbatim).
  ///
  /// In en, this message translates to:
  /// **'Sort and follow up on every inquiry so nothing slips through.'**
  String get onboardingSlideThreeBody;

  /// NavRow title on create-listing (SCREENS.md §26).
  ///
  /// In en, this message translates to:
  /// **'Add New Post'**
  String get listingEditorCreateNavTitle;

  /// NavRow title on edit-listing (SCREENS.md §27).
  ///
  /// In en, this message translates to:
  /// **'Update New Post'**
  String get listingEditorEditNavTitle;

  /// NavRow title on publish-status (SCREENS.md §29).
  ///
  /// In en, this message translates to:
  /// **'Publish Status'**
  String get listingEditorPublishStatusNavTitle;

  /// Back button label in create-listing's step footer (ListingWizardFooter) — null/hidden on step 1.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get listingEditorWizardBackLabel;

  /// Primary footer button label on create-listing's steps 1-3 (advances to the next step).
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get listingEditorWizardNextLabel;

  /// Primary footer button label on create-listing's step 4 (submits the whole form).
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get listingEditorWizardCreateLabel;

  /// Inline reason rendered beside create-listing's footer button when it is disabled, so the control that gates listing creation says why it cannot be pressed rather than only looking slightly dimmer.
  ///
  /// In en, this message translates to:
  /// **'Fill in the required fields to continue.'**
  String get listingEditorWizardDisabledReasonMessage;

  /// Step-indicator dot label on create-listing, step 1 of 4 (SCREENS.md §26).
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get listingEditorStepBasicsLabel;

  /// Step-indicator dot label on create-listing, step 2 of 4.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get listingEditorStepDetailsLabel;

  /// Step-indicator dot label on create-listing, step 3 of 4.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get listingEditorStepPhotosLabel;

  /// Step-indicator dot label on create-listing, step 4 of 4.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get listingEditorStepPublishLabel;

  /// Semantics label (screen-reader only) on a completed dot in create/edit-listing's step indicator (step_indicator.dart), which is tappable so a typo on step 1 can be fixed from step 4 without walking Back three times. {step} is the step's own dot label — listingEditorStepBasicsLabel and friends.
  ///
  /// In en, this message translates to:
  /// **'Go to {step}'**
  String listingEditorStepGoToSemanticsLabel(String step);

  /// Body text of create-listing's Step 4 stand-in notice — an honest explainer for why the real per-channel publish buttons aren't shown yet (the ad doesn't exist server-side until Create is tapped).
  ///
  /// In en, this message translates to:
  /// **'Publishing is available once this listing is created — tap Create, then use the per-channel buttons on the listing\'s own edit screen.'**
  String get listingEditorCreatePublishNoticeMessage;

  /// Heading of the read-only recap card on create-listing's Step 4, above the publish rows: it reprints what the wizard is about to submit (title, city/district, price, rooms/area, photo count) so Create is pressed against visible facts rather than three collapsed steps.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get listingEditorSummaryCardTitle;

  /// Value of the photo-count row on create-listing's Step 4 summary card (its label is listingEditorStepPhotosLabel). Counts successfully uploaded photos only, video excluded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} photo} other{{count} photos}}'**
  String listingEditorSummaryPhotosCount(int count);

  /// Placeholder value on a create-listing Step 4 summary row whose field was left empty (an optional field such as Rooms or Area) — shown in place of the value, never in place of the label.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get listingEditorSummaryNotSetLabel;

  /// Error toast shown by create-listing's Create and edit-listing's Save when a picked photo/video is still mid-upload and has no URL yet to submit.
  ///
  /// In en, this message translates to:
  /// **'Please wait for photos/video to finish uploading.'**
  String get listingEditorPendingUploadsMessage;

  /// Error toast shown by create-listing's Create and edit-listing's Save when a picked photo's or video's upload FAILED (as opposed to listingEditorPendingUploadsMessage's still-in-flight case), blocking submit. Without this block the wizard submits the ad with the failed media silently dropped and still shows the success toast, so the agent believes photos they can see in the picker were published. Says 'photos/video' like its sibling listingEditorPendingUploadsMessage because photo and video share one media list and one failure path (_startUpload takes `required bool isVideo` and its catchError marks the item failed either way), so a failed video would otherwise be reported as a photo. Names remove-and-re-add as the ONLY way out: the failed tile renders a remove badge and nothing else (photos_step.dart's _PhotoTile and _VideoTile), with no affordance anywhere that re-fires the upload for a failed item, so the copy must not promise a retry. If a per-tile retry ever lands (listingEditorRetryUploadLabel), this sentence's remove-and-re-add instruction needs revisiting with the spec owner — it is deliberately unchanged for now.
  ///
  /// In en, this message translates to:
  /// **'Some photos/video didn\'t upload. Remove them and add them again before saving.'**
  String get listingEditorFailedUploadsMessage;

  /// Transient pending-toast label while create-listing's Create request is in flight.
  ///
  /// In en, this message translates to:
  /// **'Creating'**
  String get listingEditorCreatePendingLabel;

  /// Success toast after create-listing's Create request resolves.
  ///
  /// In en, this message translates to:
  /// **'Successfully created'**
  String get listingEditorCreateSuccessMessage;

  /// Transient pending-toast label while edit-listing's Save request is in flight.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get listingEditorUpdatePendingLabel;

  /// Success toast after edit-listing's Save request resolves.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated'**
  String get listingEditorUpdateSuccessMessage;

  /// Transient pending-toast label while edit-listing's Delete request is in flight.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get listingEditorDeletePendingLabel;

  /// Success toast after edit-listing's Delete request resolves.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get listingEditorDeleteSuccessMessage;

  /// Fallback error toast/message reused across listing_editor (create-listing's Create, edit-listing's Save/Delete, publish-channels-sheet, publish-status) whenever a failure isn't a recognized ApiErrorException/NetworkException.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get listingEditorGenericErrorMessage;

  /// Fallback error message reused across listing_editor (publish-channels-sheet, publish-status) specifically for a NetworkException.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get listingEditorNetworkErrorMessage;

  /// Full-width error-state message on edit-listing when the prefill fetch (GET /ads/:id) fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this listing.'**
  String get listingEditorLoadErrorMessage;

  /// The noun edit-listing passes as shared/widgets/delete_confirm.dart's `subject` argument, which that shared widget interpolates into its own sharedDeleteConfirmTitle ("Delete {subject}?") — delete_confirm.dart requires the caller to already have a localized noun in hand (see that file's doc comment), so this is that noun for the listing/ad domain object (GLOSSARY.md's "listing / ad" entry).
  ///
  /// In en, this message translates to:
  /// **'listing'**
  String get listingEditorDeleteConfirmSubject;

  /// Field label on create-listing/edit-listing's Basics step, the listing's title text field (SCREENS.md §26).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get listingEditorTitleFieldLabel;

  /// Field label on the Basics step for the City text field.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get listingEditorCityFieldLabel;

  /// Field label on the Basics step for the District text field (disabled until City has a value).
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get listingEditorDistrictFieldLabel;

  /// Hint text shown inside the District field on the Basics step while it is disabled because City is still empty.
  ///
  /// In en, this message translates to:
  /// **'Pick a city first'**
  String get listingEditorDistrictDisabledHint;

  /// Field label on the Basics step for the Address text field.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get listingEditorAddressFieldLabel;

  /// Field label on the Basics step for the Reference text field.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get listingEditorReferenceFieldLabel;

  /// Hint text inside the Reference field on the Basics step.
  ///
  /// In en, this message translates to:
  /// **'Orientation / landmark'**
  String get listingEditorReferenceHint;

  /// Chip-group field label on the Details step for the Type (Residential/Nonresidential) selector.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get listingEditorTypeFieldLabel;

  /// Chip-group field label on the Details step for the Category (Rent/Sale) selector.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get listingEditorCategoryFieldLabel;

  /// Chip-group field label on the Details step for the Repair-condition selector.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get listingEditorRepairFieldLabel;

  /// Chip-group field label on the Details step for the Furniture selector.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get listingEditorFurnitureFieldLabel;

  /// Chip-group field label on the Details step for the currency (so'm/y.e) selector.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get listingEditorPriceTypeFieldLabel;

  /// Chip-group field label on the Details step for the ad Status (Active/Sold/Draft) selector.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get listingEditorStatusFieldLabel;

  /// Field label on the Details step for the Rooms number field.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get listingEditorRoomsFieldLabel;

  /// Field label on the Details step for the Area number field.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get listingEditorAreaFieldLabel;

  /// Unit suffix shown inside the Area field on the Details step. A metric unit symbol — likely unchanged across en/uz/ru, but extracted like any other user-visible string rather than assumed; flagged in parts/editor.json for translator confirmation.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get listingEditorAreaUnitSuffix;

  /// Field label on the Details step for the unit's own floor number field.
  ///
  /// In en, this message translates to:
  /// **'Storey'**
  String get listingEditorStoreyFieldLabel;

  /// Field label on the Details step for the building's total-floors number field.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get listingEditorFloorsFieldLabel;

  /// Field label on create-listing's Details step for the Hashtags text field (edit-listing omits this field per §27).
  ///
  /// In en, this message translates to:
  /// **'Hashtags'**
  String get listingEditorHashtagsFieldLabel;

  /// Example hint text inside the Hashtags field — sample hashtag text, not a sentence; flagged in parts/editor.json since hashtags conventionally stay in Latin script regardless of app language.
  ///
  /// In en, this message translates to:
  /// **'#new #2024'**
  String get listingEditorHashtagsHint;

  /// Field label on the Details step for the Price number field.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get listingEditorPriceFieldLabel;

  /// Field label on the Details step for the required Description text field.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get listingEditorDescriptionFieldLabel;

  /// Chip option label in the Details step's Type field.
  ///
  /// In en, this message translates to:
  /// **'Residential'**
  String get listingEditorTypeResidentialOption;

  /// Chip option label in the Details step's Type field.
  ///
  /// In en, this message translates to:
  /// **'Nonresidential'**
  String get listingEditorTypeNonresidentialOption;

  /// Chip option label in the Details step's Category field — see GLOSSARY.md's "rent" entry.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get listingEditorCategoryRentOption;

  /// Chip option label in the Details step's Category field — see GLOSSARY.md's "sale" entry.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get listingEditorCategorySaleOption;

  /// Chip option label in the Details step's Repair field — also this field's default.
  ///
  /// In en, this message translates to:
  /// **'Not repaired'**
  String get listingEditorRepairNotRepairedOption;

  /// Chip option label in the Details step's Repair field.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get listingEditorRepairNormalOption;

  /// Chip option label in the Details step's Repair field.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get listingEditorRepairGoodOption;

  /// Chip option label in the Details step's Repair field.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get listingEditorRepairExcellentOption;

  /// Chip option label in the Details step's Furniture field — also this field's default. Lowercase "furniture" is byte-exact from the source string.
  ///
  /// In en, this message translates to:
  /// **'With furniture'**
  String get listingEditorFurnitureWithOption;

  /// Chip option label in the Details step's Furniture field. Capitalised "Furniture" (unlike listingEditorFurnitureWithOption's lowercase) is byte-exact from the source string, not a typo to fix.
  ///
  /// In en, this message translates to:
  /// **'Without Furniture'**
  String get listingEditorFurnitureWithoutOption;

  /// Chip option label in the Details step's Price-type field, and the currency suffix shown in the live price preview beneath the Price field, for CurrencyCode.uzs. A currency name — flagged in parts/editor.json for translator confirmation on whether it should ever change form across languages.
  ///
  /// In en, this message translates to:
  /// **'so\'m'**
  String get listingEditorPriceTypeUzsOption;

  /// Chip option label in the Details step's Price-type field, and the currency suffix in the live price preview, for CurrencyCode.usd. Same translator-confirmation flag as listingEditorPriceTypeUzsOption.
  ///
  /// In en, this message translates to:
  /// **'y.e'**
  String get listingEditorPriceTypeUsdOption;

  /// Chip option label in the Details step's Status field — also this field's default.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get listingEditorStageActiveOption;

  /// Chip option label in the Details step's Status field.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get listingEditorStageSoldOption;

  /// Chip option label in the Details step's Status field.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get listingEditorStageDraftOption;

  /// Placeholder line under the Price field on the Details step, shown while the field is empty/unparsable.
  ///
  /// In en, this message translates to:
  /// **'Enter a price to see a preview.'**
  String get listingEditorPricePreviewPlaceholder;

  /// Live price preview under the Price field on the Details step once a number has been entered, e.g. "78,000 so'm". {amount} is the already-grouped-thousands numeral (Formatters.groupedNumber) and {currency} is the localized currency suffix (listingEditorPriceTypeUzsOption/listingEditorPriceTypeUsdOption) — both pre-formatted data passed in as placeholders rather than concatenated in Dart, so a language needing a different amount/currency order could still reorder this template.
  ///
  /// In en, this message translates to:
  /// **'{amount} {currency}'**
  String listingEditorPricePreviewText(String amount, String currency);

  /// Field label on the Details step above the Nearby Places dynamic chip list.
  ///
  /// In en, this message translates to:
  /// **'Nearby Places'**
  String get listingEditorNearbyPlacesLabel;

  /// Hint text inside the Nearby Places free-text input.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chilonzor metro station (7 min walk)'**
  String get listingEditorNearbyPlacesHint;

  /// Button label that appends the typed value as a new Nearby Places chip.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get listingEditorNearbyPlacesAddButtonLabel;

  /// Field label on the Details step above the Additional Info dynamic key/value rows.
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get listingEditorAdditionalInfoLabel;

  /// Button label that appends a new blank Additional Info row.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get listingEditorAdditionalInfoAddButtonLabel;

  /// Hint text inside an Additional Info row's key text field.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get listingEditorAdditionalInfoKeyHint;

  /// Hint text inside an Additional Info row's value text field.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get listingEditorAdditionalInfoValueHint;

  /// Message shown in edit-listing's Existing Photos grid when the ad has no photos yet.
  ///
  /// In en, this message translates to:
  /// **'No photos on this listing yet.'**
  String get listingEditorNoExistingPhotosMessage;

  /// Field label on edit-listing above the Existing Photos grid (SCREENS.md §27).
  ///
  /// In en, this message translates to:
  /// **'Existing Photos'**
  String get listingEditorExistingPhotosLabel;

  /// Field label on edit-listing above the new-upload photo/video picker, distinct from the Existing Photos grid above it.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get listingEditorAddPhotosLabel;

  /// Both the semantics label and the visible label on the in-grid "add photo" tile that closes the Photos step's picker grid (create-listing Step 3 and edit-listing's new-upload picker).
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get listingEditorAddPhotosButtonLabel;

  /// Both the semantics label and the title of the "add video" list row under the Photos step's picker grid.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get listingEditorAddVideoButtonLabel;

  /// Subtitle of the Photos step's "add video" list row — the video is optional and capped at 70 MB (SCREENS.md §26).
  ///
  /// In en, this message translates to:
  /// **'Optional · up to 70 MB'**
  String get listingEditorAddVideoOptionalHint;

  /// Caption under the Photos step's photo tiles stating the size/count limits (SCREENS.md §26).
  ///
  /// In en, this message translates to:
  /// **'Up to 5 images (5MB each). An optional single video up to 70MB.'**
  String get listingEditorMediaLimitsHint;

  /// Title of the camera-vs-gallery source-picker sheet opened by the Photos step's "add photo" tap target.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get listingEditorAddPhotoSheetTitle;

  /// Title of the camera-vs-gallery source-picker sheet opened by the Photos step's "add video" tap target.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get listingEditorAddVideoSheetTitle;

  /// Fallback label shown for a picked video tile on the Photos step when the picker returned no file name.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get listingEditorVideoFallbackFileName;

  /// Fallback status text on a failed video-upload tile in the Photos step, used only when the upload's own errorMessage is null.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload. Please try again.'**
  String get listingEditorUploadFailedFallbackMessage;

  /// Status text on a video tile in the Photos step once its upload has finished successfully.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get listingEditorUploadedStatusLabel;

  /// Status text on a video tile in the Photos step while its upload is in progress. {percent} is a plain 0-100 integer, not a countable noun, so this is a bare placeholder rather than an ICU plural.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String listingEditorUploadingProgressLabel(int percent);

  /// Action label on a failed photo/video tile in the Photos step that re-fires the upload for that one item. Distinct from sharedRetryLabel's bare "Retry" because it sits directly under an error line on a 100dp tile and has to name what is being retried.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get listingEditorRetryUploadLabel;

  /// Field label above the per-channel publish buttons (create-listing's Step 4 notice sits below this same label; edit-listing shows the real buttons under it).
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get listingEditorPublishSectionLabel;

  /// Channel name, reused as: the publish-button label on the Publish section, the section heading on publish-channels-sheet, and one of publish-status's per-channel row titles.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get listingEditorChannelInstagramLabel;

  /// Channel name, reused the same way as listingEditorChannelInstagramLabel.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get listingEditorChannelTelegramLabel;

  /// Channel name, reused as: the (visibly-disabled) publish-button label on the Publish section, and one of publish-status's per-channel row titles.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get listingEditorChannelYoutubeLabel;

  /// Channel name, reused as: the (visibly-disabled) publish-button label on the Publish section, the always-disabled row on publish-channels-sheet, and one of publish-status's per-channel row titles.
  ///
  /// In en, this message translates to:
  /// **'OLX'**
  String get listingEditorChannelOlxLabel;

  /// Channel name, reused as: the (visibly-disabled) publish-button label on the Publish section, create-listing's Step 4 row title, and the always-disabled row on publish-channels-sheet. Never a publish-status row title — Channel.fromWire cannot produce Channel.threads, so the server never returns one.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get listingEditorChannelThreadsLabel;

  /// Channel name, reused the same way as listingEditorChannelThreadsLabel.
  ///
  /// In en, this message translates to:
  /// **'Facebook Marketplace'**
  String get listingEditorChannelFacebookMarketplaceLabel;

  /// Channel name, reused the same way as listingEditorChannelThreadsLabel. The brand is the single letter X (formerly Twitter) — a bare glyph, not an abbreviation to expand.
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get listingEditorChannelXLabel;

  /// Channel name, reused the same way as listingEditorChannelThreadsLabel.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get listingEditorChannelLinkedinLabel;

  /// Fallback channel-name row title on publish-status for a Channel value this build doesn't otherwise recognize.
  ///
  /// In en, this message translates to:
  /// **'Unknown channel'**
  String get listingEditorChannelUnknownLabel;

  /// Hint line under the visibly-disabled YouTube button on the Publish section.
  ///
  /// In en, this message translates to:
  /// **'Beta — not available in this build.'**
  String get listingEditorYoutubeUnavailableHint;

  /// SCREENS.md §5's fixed OLX hint — quoted verbatim and reused across the Publish section's OLX button, publish-channels-sheet's always-disabled OLX row, and publish-status's grayed OLX row.
  ///
  /// In en, this message translates to:
  /// **'OLX cross-posting is only available from the desktop app (requires a browser extension).'**
  String get listingEditorOlxUnavailableHint;

  /// Hint line under the visibly-disabled Threads row on the Publish section, create-listing's Step 4, and publish-channels-sheet (ruling 7.10's visibly-disabled treatment). Client-authored: apps/api has no Threads publish route in this build, so there is no server copy to quote.
  ///
  /// In en, this message translates to:
  /// **'Threads posting needs a Threads profile linked to an Instagram professional account — this build never requests that permission.'**
  String get listingEditorThreadsUnavailableHint;

  /// Hint line under the visibly-disabled Facebook Marketplace row on the same three surfaces as listingEditorThreadsUnavailableHint. States SCREENS.md §5's own reason for the channel (no compliant automation path on any platform), which publish_section.dart's doc comment already recorded back when the channel was omitted outright.
  ///
  /// In en, this message translates to:
  /// **'Facebook Marketplace has no compliant automation path on any platform — its listings have to be posted by hand.'**
  String get listingEditorFacebookMarketplaceUnavailableHint;

  /// Hint line under the visibly-disabled X row on the same three surfaces as listingEditorThreadsUnavailableHint. Client-authored: apps/api has no X publish route in this build, so there is no server copy to quote.
  ///
  /// In en, this message translates to:
  /// **'X posting needs its own X API app on a paid write tier — neither is set up in this build.'**
  String get listingEditorXUnavailableHint;

  /// Hint line under the visibly-disabled LinkedIn row on the same three surfaces as listingEditorThreadsUnavailableHint. Client-authored: apps/api has no LinkedIn publish route in this build, so there is no server copy to quote.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn posting needs an approved LinkedIn Marketing API app — this build has no LinkedIn credentials.'**
  String get listingEditorLinkedinUnavailableHint;

  /// Trailing link label on edit-listing's Publish section (SCREENS.md §27) that pushes publish-status.
  ///
  /// In en, this message translates to:
  /// **'Publish Status'**
  String get listingEditorPublishStatusLinkLabel;

  /// Header title on publish-channels-sheet (SCREENS.md §28).
  ///
  /// In en, this message translates to:
  /// **'Select the channels you want to publish to!'**
  String get listingEditorPublishChannelsSheetTitle;

  /// Inline error message on publish-channels-sheet's Instagram section when the connected-accounts fetch fails. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load connected Instagram accounts.'**
  String get listingEditorInstagramLoadErrorMessage;

  /// Subtitle of an Instagram row on publish-channels-sheet, under the account's username. The follower count is pre-grouped by Formatters.groupedNumber, and the label word never inflects with it (SCREENS.md §28). Only shown when the wire actually carries a follower count; the bare channel name is used otherwise.
  ///
  /// In en, this message translates to:
  /// **'Instagram · {count} followers'**
  String listingEditorInstagramFollowersSubtitle(String count);

  /// Message on publish-channels-sheet's Instagram section when the caller has no connected Instagram account at all.
  ///
  /// In en, this message translates to:
  /// **'No Instagram account is connected. You can connect one in Settings, or draft the post yourself.'**
  String get listingEditorNoInstagramAccountMessage;

  /// Message on publish-channels-sheet's Telegram section when the caller has no connected Telegram chat.
  ///
  /// In en, this message translates to:
  /// **'No Telegram channel is connected.'**
  String get listingEditorNoTelegramChannelMessage;

  /// Row label for one connected Telegram chat on publish-channels-sheet. Telegram chats carry no title/avatar on this build's wire data (ruling 7.10), so the raw chat id is the honest label — {chatId} is a bare numeric id, not a countable noun.
  ///
  /// In en, this message translates to:
  /// **'Telegram channel #{chatId}'**
  String listingEditorTelegramChannelRowLabel(int chatId);

  /// Footer button label on publish-channels-sheet that dismisses it without publishing.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get listingEditorCancelButtonLabel;

  /// Footer button label on publish-channels-sheet that fans out the selected Instagram/Telegram publish calls.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get listingEditorPublishButtonLabel;

  /// Error toast on publish-channels-sheet when at least one selected Instagram target failed to publish. {usernames} is a comma-and-space-joined list of usernames (or raw ids when a username isn't known), already assembled in Dart before being passed in — this string only supplies the surrounding sentence.
  ///
  /// In en, this message translates to:
  /// **'Instagram publish failed for {usernames}'**
  String listingEditorInstagramPublishFailedMessage(String usernames);

  /// Success toast on publish-channels-sheet when every selected Instagram target published successfully — SCREENS.md §28 quotes this verbatim.
  ///
  /// In en, this message translates to:
  /// **'Instagram post published!'**
  String get listingEditorInstagramPublishSuccessMessage;

  /// Error toast on publish-channels-sheet when at least one selected Telegram target failed to publish and the server gave no more specific message. {chatIds} is a comma-and-space-joined list of raw chat ids, already assembled in Dart. Not spec'd text — publish_channels_sheet.dart's own doc comment documents this as an extrapolation of Instagram's spec'd pattern.
  ///
  /// In en, this message translates to:
  /// **'Telegram publish failed for {chatIds}'**
  String listingEditorTelegramPublishFailedMessage(String chatIds);

  /// Success toast on publish-channels-sheet when every selected Telegram target published successfully — same documented extrapolation as listingEditorTelegramPublishFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Telegram post published!'**
  String get listingEditorTelegramPublishSuccessMessage;

  /// Full-width error-state message on publish-status when the status fetch fails. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load publish status.'**
  String get listingEditorPublishStatusLoadErrorMessage;

  /// Trailing status text on publish-status's grayed OLX row, in place of a status pill.
  ///
  /// In en, this message translates to:
  /// **'Not available on mobile'**
  String get listingEditorOlxNotAvailableLabel;

  /// Row detail on publish-status showing when a channel was last attempted. {date} is already formatted by Formatters.date before being passed in.
  ///
  /// In en, this message translates to:
  /// **'Last attempt: {date}'**
  String listingEditorLastAttemptLabel(String date);

  /// Link label on a PUBLISHED channel row on publish-status when an external URL exists — copies the link to the clipboard (no url_launcher in this build).
  ///
  /// In en, this message translates to:
  /// **'View Post'**
  String get listingEditorViewPostLinkLabel;

  /// Toast shown after tapping listingEditorViewPostLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Post link copied to clipboard.'**
  String get listingEditorPostLinkCopiedMessage;

  /// Explanatory caption under publish-status's disabled Retry pill for a FAILED YouTube row — quoted verbatim from the live server's NON_RETRYABLE_REASONS.
  ///
  /// In en, this message translates to:
  /// **'YouTube has no server-side publish call to retry — the browser performs the upload itself under your own Google session. Upload again and report the result.'**
  String get listingEditorYoutubeNonRetryableReason;

  /// Explanatory caption under publish-status's disabled Retry pill for a FAILED OLX row — quoted verbatim from the live server's NON_RETRYABLE_REASONS.
  ///
  /// In en, this message translates to:
  /// **'OLX posting happens through the browser extension with a human reviewing and clicking Publish. Retry the cross-post from the extension instead.'**
  String get listingEditorOlxNonRetryableReason;

  /// Explanatory caption fallback for a FAILED row on a Channel value this build doesn't otherwise recognize.
  ///
  /// In en, this message translates to:
  /// **'Unknown publish channel.'**
  String get listingEditorUnknownChannelReason;

  /// Success toast on publish-status after a Telegram/Instagram Retry succeeds. {channel} is the already-localized channel name (listingEditorChannelInstagramLabel/listingEditorChannelTelegramLabel) passed in as data. Not spec'd text — publish_status_screen.dart's own doc comment documents this as an extrapolation of publish-channels-sheet's "{channel} post published!" pattern.
  ///
  /// In en, this message translates to:
  /// **'{channel} publish retried successfully.'**
  String listingEditorRetrySuccessMessage(String channel);

  /// Primary submit button label on edit-listing's form (SCREENS.md §27 — a real submit from any point, unlike create-listing's stepwise Next/Create).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get listingEditorSaveButtonLabel;

  /// Destructive Delete button label on edit-listing's form, hidden for a coworker session.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get listingEditorDeleteButtonLabel;

  /// Inline validation error under the Title field on create-listing/edit-listing, quoted verbatim from SCREENS.md §26.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get listingEditorTitleRequiredError;

  /// Inline validation error under the City field — same §26 quoting as listingEditorTitleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get listingEditorCityRequiredError;

  /// Inline validation error under the District field — same §26 quoting as listingEditorTitleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'District is required'**
  String get listingEditorDistrictRequiredError;

  /// Inline validation error under the Address field — same §26 quoting as listingEditorTitleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get listingEditorAddressRequiredError;

  /// Inline validation error under the Reference field — same §26 quoting as listingEditorTitleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Reference is required'**
  String get listingEditorReferenceRequiredError;

  /// Inline validation error under the Description field on the Details step — same §26 quoting as listingEditorTitleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get listingEditorDescriptionRequiredError;

  /// Header title on my-listings (SCREENS.md §25).
  ///
  /// In en, this message translates to:
  /// **'My Ads'**
  String get myListingsNavTitle;

  /// Toolbar button label on my-listings that opens the CRM variant of filter-sheet.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get myListingsFilterButtonLabel;

  /// Semantics label on my-listings toolbar's "+" button, which pushes create-listing.
  ///
  /// In en, this message translates to:
  /// **'Create New Post'**
  String get myListingsCreateButtonSemanticsLabel;

  /// Full-width error-state message on my-listings' row list when the paged fetch fails. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your ads.'**
  String get myListingsLoadErrorMessage;

  /// Empty-state message on my-listings when the fetch succeeds with zero ads — SCREENS.md §25's own copy, quoted verbatim.
  ///
  /// In en, this message translates to:
  /// **'Ads not found.'**
  String get myListingsEmptyStateMessage;

  /// Empty-state message on My Ads when the agent does have ads but the active status/stage filter hid all of them. The unfiltered case keeps myListingsEmptyStateMessage; showing one string for both made a filtered-out list indistinguishable from an empty account.
  ///
  /// In en, this message translates to:
  /// **'No ads match your filters.'**
  String get myListingsFilteredEmptyStateMessage;

  /// Action-pill label on My Ads' empty state, opening the create-listing wizard. A visible button label, unlike myListingsCreateButtonSemanticsLabel which is the screen-reader-only name of the header's '+' glyph.
  ///
  /// In en, this message translates to:
  /// **'Create New Post'**
  String get myListingsEmptyStateActionLabel;

  /// Semantics label on each my-listings row's edit icon, which pushes edit-listing for that ad.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get myListingsEditButtonSemanticsLabel;

  /// First segment of the stage-count strip in the My Ads header — selecting it clears the stage filter and shows every ad. Exists so a segment-as-filter shortcut always has a visible way back out.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get myListingsStageAllLabel;

  /// Active segment of the stage-count strip in the My Ads header, backed by GET /my/ads/stage-counts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} active} other{{count} active}}'**
  String myListingsStageCountActiveLabel(int count);

  /// Sold segment of the stage-count strip in the My Ads header, backed by GET /my/ads/stage-counts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} sold} other{{count} sold}}'**
  String myListingsStageCountSoldLabel(int count);

  /// Draft segment of the stage-count strip in the My Ads header — the one aggregate an agent acts on daily, backed by GET /my/ads/stage-counts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} draft} other{{count} drafts}}'**
  String myListingsStageCountDraftLabel(int count);

  /// Screen-reader name for one segment of the My Ads stage-count strip when the segment doubles as a filter shortcut; {stage} is an already-localized stage word (Active/Sold/Draft/All).
  ///
  /// In en, this message translates to:
  /// **'Show {stage} ads'**
  String myListingsStageFilterSemanticsLabel(String stage);

  /// Published state of one channel badge in a My Ads row's channel strip. A human word, unlike the raw wire enums publish-status quotes verbatim.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get myListingsChannelPublishedLabel;

  /// Failed state of one channel badge in a My Ads row's channel strip — the state that today is only findable two screens deep.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get myListingsChannelFailedLabel;

  /// In-flight state of one channel badge in a My Ads row's channel strip.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get myListingsChannelPendingLabel;

  /// Never-attempted state of one channel badge in a My Ads row's channel strip — distinct from Failed, which is an attempt that came back with an error.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get myListingsChannelNotPublishedLabel;

  /// Screen-reader name for one channel badge in a My Ads row: the channel name (Instagram/Telegram/…) followed by its already-localized publish state, since the badge itself is a tinted glyph with no readable text.
  ///
  /// In en, this message translates to:
  /// **'{channel} — {status}'**
  String myListingsChannelBadgeSemanticsLabel(String channel, String status);

  /// Nav-bar title on the Agents directory screen (SCREENS.md §3.9).
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentsDirectoryScreenTitle;

  /// Full-width error-state message on Agents directory when the list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load agents'**
  String get agentsDirectoryLoadErrorMessage;

  /// Full-width empty-state message on Agents directory when the list loads with zero agents (SCREENS.md §3.9, quoted verbatim).
  ///
  /// In en, this message translates to:
  /// **'No agents found.'**
  String get agentsDirectoryEmptyMessage;

  /// SCREENS.md §3.9's "Ads: {adsCount}" chip on an Agent directory card — quoted verbatim; the count is intentionally not pluralized (matches the file's own doc comment), it's a fixed label followed by a numeral.
  ///
  /// In en, this message translates to:
  /// **'Ads: {count}'**
  String agentsCardAdsCountLabel(int count);

  /// Semantics label (screen-reader only, no visible text) on the agent-profile screen's back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get agentsProfileNavBackLabel;

  /// Nav-bar title on the agent-profile screen (SCREENS.md §3.10).
  ///
  /// In en, this message translates to:
  /// **'Agent Information'**
  String get agentsProfileScreenTitle;

  /// Full-width error-state message on agent-profile when a transport failure (not a 404) prevents loading.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this agent'**
  String get agentsProfileLoadErrorMessage;

  /// Full-width state message on agent-profile when the agent id 404s (a deleted account, or a coworker id GET /agents/:id refuses by design).
  ///
  /// In en, this message translates to:
  /// **'This agent is no longer available.'**
  String get agentsProfileNotFoundMessage;

  /// Action-button label on agent-profile's not-found state, navigating back to the agents directory.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get agentsProfileGoBackLabel;

  /// Field label in the agent-profile identity block (SCREENS.md §3.10, quoted with its own casing and trailing colon).
  ///
  /// In en, this message translates to:
  /// **'Full name:'**
  String get agentsInfoFullNameLabel;

  /// Field label in the agent-profile identity block (SCREENS.md §3.10, quoted with its own hyphenated casing and trailing colon).
  ///
  /// In en, this message translates to:
  /// **'E-mail:'**
  String get agentsInfoEmailLabel;

  /// Field label in the agent-profile identity block (SCREENS.md §3.10, quoted with its own casing and trailing colon).
  ///
  /// In en, this message translates to:
  /// **'Phone:'**
  String get agentsInfoPhoneLabel;

  /// Field label in the agent-profile identity block for the agent's address, shown only when set.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get agentsInfoAddressLabel;

  /// Field label in agent-profile's identity block, on the row carrying the agent's aggregate star rating. Same label:value shape as the name/e-mail/phone/address rows beside it.
  ///
  /// In en, this message translates to:
  /// **'Rating:'**
  String get agentsInfoRatingLabel;

  /// Action-button label in the agent-profile identity block that dials the agent's phone number.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get agentsInfoCallButtonLabel;

  /// Action-button label in the agent-profile identity block that opens contact-sheet pre-filled for this agent.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get agentsInfoMessageButtonLabel;

  /// Scoped error message on agent-profile's Ads List grid when it fails to load (the identity block above stays intact — see this file's doc comment).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this agent\'s listings'**
  String get agentsAdsGridLoadErrorMessage;

  /// Empty-state message on agent-profile's Ads List grid (SCREENS.md §3.10, quoted verbatim, matches list_states.dart's app-wide wording).
  ///
  /// In en, this message translates to:
  /// **'No listings found.'**
  String get agentsAdsGridEmptyMessage;

  /// Heading above agent-profile's Ads List grid, shown while the count is not yet known (loading/error).
  ///
  /// In en, this message translates to:
  /// **'Ads List'**
  String get agentsAdsGridHeading;

  /// Inline form error in the review sheet when Submit is tapped with no star selected.
  ///
  /// In en, this message translates to:
  /// **'Please choose a rating.'**
  String get reviewsRatingRequiredError;

  /// Success toast after editing an existing agent review in the review sheet.
  ///
  /// In en, this message translates to:
  /// **'Review updated.'**
  String get reviewsUpdateSuccessToast;

  /// Success toast after posting a new agent review in the review sheet.
  ///
  /// In en, this message translates to:
  /// **'Review posted.'**
  String get reviewsPostSuccessToast;

  /// Success toast after deleting the signed-in caller's own agent review.
  ///
  /// In en, this message translates to:
  /// **'Review deleted.'**
  String get reviewsDeleteSuccessToast;

  /// Inline error banner in the review sheet when the server's forbidden (403) self-review check fires on submit.
  ///
  /// In en, this message translates to:
  /// **'You can\'t review yourself.'**
  String get reviewsSelfReviewForbiddenError;

  /// Inline error banner in the review sheet when the agent record 404s while submitting a review. Distinct key from agentsProfileNotFoundMessage even though the English text coincides — different screen, different role (inline form error vs. full-width screen state).
  ///
  /// In en, this message translates to:
  /// **'This agent is no longer available.'**
  String get reviewsAgentNotFoundError;

  /// Fallback error in the review sheet for any submit/delete failure not covered by a more specific message (an unrecognized ApiErrorCode, or the sheet's own final fallback return).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your review right now. Please try again.'**
  String get reviewsSaveGenericErrorMessage;

  /// Fallback message in the review sheet when submit/delete fails with no server response (NetworkException).
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get reviewsNetworkErrorMessage;

  /// Title of the review sheet when the signed-in caller already has a review on this agent (upsert path).
  ///
  /// In en, this message translates to:
  /// **'Edit Your Review'**
  String get reviewsSheetEditTitle;

  /// Title of the review sheet when the signed-in caller has no existing review on this agent.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get reviewsSheetLeaveTitle;

  /// Semantics label on the review sheet's close 'X' button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get reviewsSheetCloseLabel;

  /// Subtitle under the review sheet's title, naming the agent being reviewed.
  ///
  /// In en, this message translates to:
  /// **'Share your experience working with {agentName}.'**
  String reviewsSheetPromptMessage(String agentName);

  /// All-caps field label above the review sheet's comment textarea — a literal all-caps string in source, not a `.toUpperCase()` call.
  ///
  /// In en, this message translates to:
  /// **'COMMENT (OPTIONAL)'**
  String get reviewsSheetCommentLabel;

  /// Hint text inside the review sheet's empty comment textarea.
  ///
  /// In en, this message translates to:
  /// **'What was it like working with this agent?'**
  String get reviewsSheetCommentHint;

  /// Submit-button label in the review sheet when editing an existing review.
  ///
  /// In en, this message translates to:
  /// **'Update review'**
  String get reviewsSheetUpdateButtonLabel;

  /// Submit-button label in the review sheet when posting a new review.
  ///
  /// In en, this message translates to:
  /// **'Post review'**
  String get reviewsSheetPostButtonLabel;

  /// Transient label on the review sheet's delete link while the delete request is in flight.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get reviewsSheetDeletingLabel;

  /// Tappable text link in the review sheet that deletes the signed-in caller's existing review, shown only when one exists.
  ///
  /// In en, this message translates to:
  /// **'Delete review'**
  String get reviewsSheetDeleteButtonLabel;

  /// Heading above agent-profile's reviews list, counting agent.ratingCount — a heading with a parenthetical count, not an inflecting noun phrase, so a plain placeholder rather than an ICU plural (same idiom as agentsAdsGridHeadingWithCount).
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String reviewsSectionHeading(int count);

  /// Scoped error message on agent-profile's reviews section when the reviews page fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this agent\'s reviews'**
  String get reviewsSectionLoadErrorMessage;

  /// Empty-state message on agent-profile's reviews section when the agent has zero reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get reviewsSectionEmptyMessage;

  /// Call-to-action message on agent-profile's reviews section for a signed-out visitor.
  ///
  /// In en, this message translates to:
  /// **'Sign in to leave a review.'**
  String get reviewsSectionSignInPromptMessage;

  /// Pill button on agent-profile's reviews section, signed-out state, pushing the login screen.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get reviewsSectionSignInButtonLabel;

  /// Explanatory line on agent-profile's reviews section when the signed-in caller is viewing their own agent profile — no button, just an explanation.
  ///
  /// In en, this message translates to:
  /// **'You can\'t review your own profile.'**
  String get reviewsSectionSelfProfileMessage;

  /// Pill button on agent-profile's reviews section for a signed-in caller with no review of their own loaded yet.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get reviewsSectionLeaveButtonLabel;

  /// Pill button on agent-profile's reviews section for a signed-in caller whose own review was found among the loaded pages.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get reviewsSectionEditButtonLabel;

  /// Tappable text link at the bottom of agent-profile's reviews list that loads the next page.
  ///
  /// In en, this message translates to:
  /// **'Show more reviews'**
  String get reviewsSectionLoadMoreLabel;

  /// Nav-bar title on profile-agent, the Profile tab's body for a signed-in agent/coworker (SCREENS.md §3.16).
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileAgentScreenTitle;

  /// Group-label heading on profile-agent above the Edit Profile/Connected Accounts/Settings/Messages/Language rows.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAgentAccountGroupLabel;

  /// Row title on profile-agent that pushes edit-profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileAgentEditProfileRowTitle;

  /// Agent-only row title on profile-agent (SCREENS.md §3.16's own "(agent only)" annotation), pushes the Connected Accounts screen.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get profileAgentConnectedAccountsRowTitle;

  /// Row title on profile-agent that pushes the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileAgentSettingsRowTitle;

  /// Row title on profile-agent that pushes a not-yet-registered Messages route.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get profileAgentMessagesRowTitle;

  /// Row title on profile-agent that opens the language-sheet bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileAgentLanguageRowTitle;

  /// Group-label heading on profile-agent above the single Browse/Work mode-switch row.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get profileAgentWorkspaceGroupLabel;

  /// Mode-switch row on profile-agent shown while the agent is in the 5-tab work shell; leaves it for the 4-tab buyer shell (Home/Search/Agents/Profile). See lib/navigation/workspace_mode.dart.
  ///
  /// In en, this message translates to:
  /// **'Browse listings'**
  String get profileAgentBrowseModeRowTitle;

  /// Subtitle under profileAgentBrowseModeRowTitle, saying what the buyer shell is for an agent (comparables, competitors' listings).
  ///
  /// In en, this message translates to:
  /// **'Search and view ads like a client'**
  String get profileAgentBrowseModeRowSubtitle;

  /// Mode-switch row on profile-agent shown while the agent is in the buyer shell; returns them to the 5-tab work shell.
  ///
  /// In en, this message translates to:
  /// **'Go to workspace'**
  String get profileAgentWorkModeRowTitle;

  /// Subtitle under profileAgentWorkModeRowTitle, naming the four work tabs it leads back to.
  ///
  /// In en, this message translates to:
  /// **'Statistics, ads, leads and coworkers'**
  String get profileAgentWorkModeRowSubtitle;

  /// Group-label heading on profile-agent above the Logout row.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get profileAgentSessionGroupLabel;

  /// Destructive (red) row title on profile-agent; signs the user out after a confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileAgentLogoutRowTitle;

  /// Nav-bar title on profile-buyer, the Profile tab's body for a signed-in buyer (SCREENS.md §3.15).
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileBuyerScreenTitle;

  /// Group-label heading on profile-buyer above the Saved Listings/Update Profile/Language/Register-as-Agent rows.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileBuyerAccountGroupLabel;

  /// Row title on profile-buyer that pushes the saved-listings screen.
  ///
  /// In en, this message translates to:
  /// **'Saved Listings'**
  String get profileBuyerSavedListingsRowTitle;

  /// `.lrow__s` subtitle under profile-buyer's Saved Listings row, stating how many listings are saved — the mockup shows '4 listings' there. Unlike every other row's subtitle on this screen, which is static copy, this one is live data: it reads the length of the app-wide favourited-ad-id set, so it costs no fetch of its own. The =0 case is spelled out because an empty set is the ordinary first-run state, and '0 listings' reads worse than 'No listings'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No listings} one{{count} listing} other{{count} listings}}'**
  String profileBuyerSavedListingsRowSubtitle(int count);

  /// Row title on profile-buyer that pushes edit-profile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get profileBuyerUpdateProfileRowTitle;

  /// Row title on profile-buyer that opens the language-sheet bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileBuyerLanguageRowTitle;

  /// Row title on profile-buyer that opens the external "Register as Agent" Google Form in a browser.
  ///
  /// In en, this message translates to:
  /// **'Register as Agent'**
  String get profileBuyerRegisterAsAgentRowTitle;

  /// Title of the non-tappable status card that replaces the 'Register as Agent' row on buyer-profile while the signed-in user's realtor application is pending.
  ///
  /// In en, this message translates to:
  /// **'Realtor application under review'**
  String get profileBuyerRealtorPendingRowTitle;

  /// Subtitle of buyer-profile's pending-realtor card, naming the number the office will ring (RealtorProfile.officePhone, or the account's own phone).
  ///
  /// In en, this message translates to:
  /// **'We\'ll call {phone} — usually within one business day.'**
  String profileBuyerRealtorPendingRowSubtitle(String phone);

  /// Subtitle of buyer-profile's pending-realtor card when neither an office phone nor an account phone is known, so there is no number to name.
  ///
  /// In en, this message translates to:
  /// **'We\'ll call you — usually within one business day.'**
  String get profileBuyerRealtorPendingNoPhoneSubtitle;

  /// Title of the status card that replaces the 'Register as Agent' row on buyer-profile when the user's realtor application was rejected — the outcome the app never told them about.
  ///
  /// In en, this message translates to:
  /// **'Realtor application not approved'**
  String get profileBuyerRealtorRejectedRowTitle;

  /// Subtitle of buyer-profile's rejected-realtor card, pointing at the card's own Contact Us action.
  ///
  /// In en, this message translates to:
  /// **'Contact us and we\'ll go through it with you.'**
  String get profileBuyerRealtorRejectedRowSubtitle;

  /// Action label on buyer-profile's rejected-realtor card, opening the Contact Us sheet. Same words as the signed-out profile's row title, different control.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get profileBuyerRealtorRejectedActionLabel;

  /// Trailing line on buyer-profile's pending/rejected realtor card showing when the application was submitted (RealtorProfile.appliedAt, pre-formatted in local time by Formatters.date).
  ///
  /// In en, this message translates to:
  /// **'Applied {date}'**
  String profileBuyerRealtorAppliedAtLabel(String date);

  /// Group-label heading on profile-buyer above the Logout row.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get profileBuyerSessionGroupLabel;

  /// Destructive (red) row title on profile-buyer; signs the user out after a confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileBuyerLogoutRowTitle;

  /// Success toast on profile-buyer's Register-as-Agent row when no browser could open the external form link, so the link was copied to the clipboard instead.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your browser — Registration form link copied instead. Paste it into your browser to apply.'**
  String get profileBuyerRegisterLinkCopiedToast;

  /// Nav-bar title on profile-signed-out, the Profile tab's body when no session is active (SCREENS.md §3.14).
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSignedOutScreenTitle;

  /// Group-label heading on profile-signed-out above the Language/Contact Us rows — deliberately not translated as "Settings" (profileAgentSettingsRowTitle/profileAgentSettingsRowTitle's own word) since the two are different concepts on different screens in this app.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSignedOutPreferencesGroupLabel;

  /// Row title on profile-signed-out that opens the language-sheet bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileSignedOutLanguageRowTitle;

  /// Row title on profile-signed-out that opens the contact-sheet bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get profileSignedOutContactUsRowTitle;

  /// Heading sentence on profile-signed-out's sign-in prompt card, quoted from SCREENS.md §3.14 exactly.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save listings, message agents, and manage your business.'**
  String get profileSignedOutPromptMessage;

  /// Filled CTA button on profile-signed-out's sign-in prompt card, pushing the login screen.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get profileSignedOutSignInButtonLabel;

  /// Outlined CTA button on profile-signed-out's sign-in prompt card, pushing the register screen.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get profileSignedOutSignUpButtonLabel;

  /// Form-level error banner on login when Email/Password is submitted empty, client-side before any request.
  ///
  /// In en, this message translates to:
  /// **'Required fields are not filled'**
  String get authLoginRequiredFieldsError;

  /// Snackbar shown after a successful sign-in on login, right after navigating to home-feed.
  ///
  /// In en, this message translates to:
  /// **'User successfully logged in.'**
  String get authLoginSuccessToast;

  /// Form-level error banner on login for ApiErrorCode.invalidCredentials (401) — SCREENS.md §3.12's fixed copy, regardless of the server's own message text.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get authLoginInvalidCredentialsError;

  /// Second line rendered under the invalid-credentials error on login, pointing at the Forgot password link. Kept as its own key so §3.12's quoted 'Invalid email or password' stays byte-identical.
  ///
  /// In en, this message translates to:
  /// **'Forgot it? Tap Forgot password.'**
  String get authLoginForgotPasswordHintMessage;

  /// Form-level error banner on login when sign-in fails with no server response (NetworkException).
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get authLoginNetworkErrorMessage;

  /// Form-level error banner on login's last-resort fallback, for an exception type not otherwise handled.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get authLoginGenericErrorMessage;

  /// Large display heading on the login screen, under the hero icon.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginWelcomeHeading;

  /// Field label on the login screen's email input (SCREENS.md §3.12, quoted).
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authLoginEmailFieldLabel;

  /// Field label on the login screen's password input (SCREENS.md §3.12, quoted).
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authLoginPasswordFieldLabel;

  /// Submit-button label on the login screen (SCREENS.md §3.12, quoted).
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLoginSubmitButtonLabel;

  /// Link under the Password field on login. Until POST /auth/forgot-password exists it opens the Contact Us sheet pre-filled with the typed email.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authLoginForgotPasswordLinkLabel;

  /// Pre-filled message body the login screen hands the Contact Us sheet when the user taps Forgot password with an email already typed.
  ///
  /// In en, this message translates to:
  /// **'I forgot the password for {email} and can\'t sign in. Please help me reset it.'**
  String authLoginForgotPasswordContactMessage(String email);

  /// Pre-filled message body the login screen hands the Contact Us sheet when Forgot password is tapped with the email field still empty.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password and can\'t sign in. Please help me reset it.'**
  String get authLoginForgotPasswordContactMessageNoEmail;

  /// The entire tappable footer link on login that pushes register — SCREENS.md §3.12's exact phrase, with no separate "Sign up" word appended (see AuthFooterLink's own doc comment for why).
  ///
  /// In en, this message translates to:
  /// **'Don\'t you have an account?'**
  String get authLoginFooterLinkText;

  /// Large display heading on the register screen, under the hero icon.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authRegisterHeading;

  /// All-caps section label above the Buyer/Realtor pick cards on register (SCREENS.md §3.13, quoted) — the widget applies .toUpperCase() to this value at the call site, so the ARB value stays mixed-case, matching the original Dart literal.
  ///
  /// In en, this message translates to:
  /// **'I\'m signing up as'**
  String get authRegisterAccountTypeLabel;

  /// Title on register's "Buyer" account-type pick card (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get authRegisterBuyerCardTitle;

  /// Subtitle on register's "Buyer" account-type pick card — non-spec judgment-call copy (see this screen's doc comment).
  ///
  /// In en, this message translates to:
  /// **'Browse and save homes'**
  String get authRegisterBuyerCardSubtitle;

  /// Title on register's "Realtor" account-type pick card (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Realtor'**
  String get authRegisterRealtorCardTitle;

  /// Subtitle on register's "Realtor" account-type pick card — non-spec judgment-call copy (see this screen's doc comment).
  ///
  /// In en, this message translates to:
  /// **'Post listings, work leads'**
  String get authRegisterRealtorCardSubtitle;

  /// Field label on register's full-name input (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authRegisterFullNameFieldLabel;

  /// Field label on register's phone input (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authRegisterPhoneFieldLabel;

  /// Field label on register's email input (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authRegisterEmailFieldLabel;

  /// Field label on register's password input (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authRegisterPasswordFieldLabel;

  /// Hint text inside register's empty password field, describing the server's minimum length.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get authRegisterPasswordHint;

  /// All-caps section label above register's Solo agent/Agency chips (SCREENS.md §3.13, quoted) — .toUpperCase() applied at the call site, ARB value stays mixed-case.
  ///
  /// In en, this message translates to:
  /// **'Realtor type'**
  String get authRegisterRealtorTypeLabel;

  /// Chip label on register for the solo-realtor kind (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Solo agent'**
  String get authRegisterSoloAgentChipLabel;

  /// Chip label on register for the agency-realtor kind (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get authRegisterAgencyChipLabel;

  /// Explanatory hint shown under register's Solo agent chip when selected — this screen's own judgment-call wording, close to but not copied verbatim from SCREENS.md's unquoted prose (see this screen's doc comment).
  ///
  /// In en, this message translates to:
  /// **'You work under your own name. Your workspace opens on Statistics with your own listings and leads; Coworkers stays hidden until you switch to an agency.'**
  String get authRegisterSoloAgentHint;

  /// Field label on register's agency-name input, shown only for the Agency realtor kind (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Agency name'**
  String get authRegisterAgencyNameFieldLabel;

  /// Quiet caption under register's Agency name field, no error connotation.
  ///
  /// In en, this message translates to:
  /// **'Shown on the team\'s listings in place of the agent\'s own name.'**
  String get authRegisterAgencyNameHelperText;

  /// Field label on register's optional office-phone input, shown only for the Agency realtor kind (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Office phone'**
  String get authRegisterOfficePhoneFieldLabel;

  /// All-caps section label above register's team-size chip row, shown only for the Agency realtor kind (SCREENS.md §3.13, quoted) — .toUpperCase() applied at the call site, ARB value stays mixed-case.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get authRegisterTeamSizeLabel;

  /// Team-size chip option on register for TeamSize.justMe — copied from apps/web/src/routes/register/register.jsx's TEAM_SIZE_LABELS (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Just me for now'**
  String get authRegisterTeamSizeJustMeLabel;

  /// Team-size chip option on register for TeamSize.twoToFive — copied from apps/web/src/routes/register/register.jsx's TEAM_SIZE_LABELS. Uses an en dash (–), not a hyphen.
  ///
  /// In en, this message translates to:
  /// **'2–5'**
  String get authRegisterTeamSizeTwoToFiveLabel;

  /// Team-size chip option on register for TeamSize.sixToFifteen — copied from apps/web/src/routes/register/register.jsx's TEAM_SIZE_LABELS. Uses an en dash (–), not a hyphen.
  ///
  /// In en, this message translates to:
  /// **'6–15'**
  String get authRegisterTeamSizeSixToFifteenLabel;

  /// Team-size chip option on register for TeamSize.sixteenPlus — copied from apps/web/src/routes/register/register.jsx's TEAM_SIZE_LABELS.
  ///
  /// In en, this message translates to:
  /// **'16+'**
  String get authRegisterTeamSizeSixteenPlusLabel;

  /// Explanatory hint shown under register's team-size chips when the Agency realtor kind is selected — this screen's own judgment-call wording (see this screen's doc comment).
  ///
  /// In en, this message translates to:
  /// **'You sign up as the agency owner: invite coworkers, assign leads to them, and see the whole team\'s statistics. Coworkers see only what you assign.'**
  String get authRegisterAgencyOwnerHint;

  /// Informational callout shown on register for either realtor kind (SCREENS.md §3.13: "Either realtor choice carries the note…", quoted).
  ///
  /// In en, this message translates to:
  /// **'Realtor accounts are verified before the Work tab unlocks. We\'ll call the number above — usually within one business day.'**
  String get authRegisterVerificationCalloutMessage;

  /// Form-level error banner on register when a required field is submitted empty, client-side before any request.
  ///
  /// In en, this message translates to:
  /// **'Required fields are not filled'**
  String get authRegisterRequiredFieldsError;

  /// Form-level error banner on register for a malformed phone or office-phone number (Formatters.isValidUzPhone), client-side before any request. One key, reused for both fields since the check and message are identical.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format'**
  String get authRegisterInvalidPhoneError;

  /// Per-field error under Sign Up's Full name field, replacing the single unnamed 'Required fields are not filled' banner for this field.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get authRegisterFullNameRequiredError;

  /// Per-field error under Sign Up's Phone number field (and the Agency branch's Office phone) when it is left empty.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get authRegisterPhoneRequiredError;

  /// Per-field error under Sign Up's Email field when it is left empty. Distinct from the server's emailTaken message, which the same errorText slot also renders.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authRegisterEmailRequiredError;

  /// Per-field error under Sign Up's Email field when what was typed isn't an email address at all.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address format'**
  String get authRegisterEmailInvalidError;

  /// Per-field error under Sign Up's Password field when it is left empty.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authRegisterPasswordRequiredError;

  /// Per-field error under Sign Up's Password field when it is shorter than the six characters authRegisterPasswordHint promises.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authRegisterPasswordTooShortError;

  /// Per-field error under Sign Up's Agency name field on the Agency branch — the field whose emptiness was previously reported only by a banner seven fields below it.
  ///
  /// In en, this message translates to:
  /// **'Agency name is required'**
  String get authRegisterAgencyNameRequiredError;

  /// Snackbar shown after a successful realtor sign-up on register, right after navigating to home-feed.
  ///
  /// In en, this message translates to:
  /// **'Account created. We\'ll verify your realtor profile shortly.'**
  String get authRegisterRealtorSuccessToast;

  /// Snackbar shown after a successful buyer sign-up on register, right after navigating to home-feed.
  ///
  /// In en, this message translates to:
  /// **'User successfully created.'**
  String get authRegisterBuyerSuccessToast;

  /// Form-level error banner on register when sign-up fails with no server response (NetworkException).
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get authRegisterNetworkErrorMessage;

  /// Form-level error banner on register's last-resort fallback, for an exception type not otherwise handled.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get authRegisterGenericErrorMessage;

  /// Submit-button label on register when signing up as a realtor (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Create realtor account'**
  String get authRegisterRealtorSubmitButtonLabel;

  /// Submit-button label on register when signing up as a buyer (SCREENS.md §3.13, quoted).
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authRegisterBuyerSubmitButtonLabel;

  /// Footer link on register that pushes login — a deliberate non-spec addition (§3.13 names no reciprocal link back to login); see this screen's doc comment for why.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authRegisterFooterLinkText;

  /// Semantics label on AuthField's password-visibility toggle icon when the password is currently obscured (shared by login and register).
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authVisibilityToggleShowLabel;

  /// Semantics label on AuthField's password-visibility toggle icon when the password is currently visible (shared by login and register).
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authVisibilityToggleHideLabel;

  /// Semantics label on AuthCloseButton, the top-right 'X' dismiss control shared by login and register.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get authCloseButtonLabel;

  /// Nav-bar title on edit-profile (SCREENS.md §3.18).
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileScreenTitle;

  /// Title of edit-profile's discard-confirmation alert, shown when leaving the form with unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editProfileDiscardDialogTitle;

  /// Button in edit-profile's discard-confirmation alert that keeps editing (dismisses the alert without leaving).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editProfileDiscardDialogCancelButtonLabel;

  /// Button in edit-profile's discard-confirmation alert that leaves the form, losing unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editProfileDiscardDialogConfirmButtonLabel;

  /// Error toast on edit-profile when Save is tapped while an avatar photo is still mid-upload.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the photo to finish uploading.'**
  String get editProfileAvatarUploadingToast;

  /// Snackbar shown after a successful profile save on edit-profile.
  ///
  /// In en, this message translates to:
  /// **'Profile successfully updated!'**
  String get editProfileUpdateSuccessToast;

  /// Snackbar shown after a failed profile save on edit-profile. {message} carries the server's own error text verbatim (ApiErrorException.message) or one of this screen's own client-authored fallback strings (editProfileNetworkErrorMessage / editProfileGenericErrorMessage) — {message} itself is never re-translated, only this template's own "Error updating profile:" wording is.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {message}'**
  String editProfileUpdateErrorToast(String message);

  /// Client-authored fallback fed into editProfileUpdateErrorToast's {message} when a profile save fails with no server response (NetworkException).
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get editProfileNetworkErrorMessage;

  /// Client-authored fallback fed into editProfileUpdateErrorToast's {message} for an exception type not otherwise handled.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get editProfileGenericErrorMessage;

  /// Full-width state message on edit-profile for the (unreachable in normal use, but possible via a deep link) signed-out case.
  ///
  /// In en, this message translates to:
  /// **'Sign in to edit your profile.'**
  String get editProfileSignedOutMessage;

  /// Action-button label on edit-profile's signed-out state.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get editProfileSignedOutGoBackLabel;

  /// Field label on edit-profile's full-name input (SCREENS.md §3.18, quoted).
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get editProfileFullNameFieldLabel;

  /// Inline error under edit-profile's full-name field when submitted empty — quoted verbatim from SCREENS.md §3.18, which mismatches its own "Full name" field label with this "First name" error text; that mismatch is the spec's own inconsistency, preserved rather than corrected (see this screen's doc comment).
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get editProfileFullNameRequiredError;

  /// Field label on edit-profile's phone input.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editProfilePhoneFieldLabel;

  /// Inline error under edit-profile's phone field when the value fails Formatters.isValidUzPhone (covers both empty and wrong-shape, per SCREENS.md's single message for both).
  ///
  /// In en, this message translates to:
  /// **'Invalid Uzbekistan phone number'**
  String get editProfilePhoneInvalidError;

  /// Field label on edit-profile's email input.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileEmailFieldLabel;

  /// Inline error under edit-profile's email field when submitted empty (a presence check only — malformed-but-non-empty is left to the server).
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get editProfileEmailRequiredError;

  /// Field label on edit-profile's optional password input.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get editProfilePasswordFieldLabel;

  /// Hint text inside edit-profile's empty password field.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep your current password'**
  String get editProfilePasswordHint;

  /// Inline error under edit-profile's password field when a non-empty value is shorter than 6 characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get editProfilePasswordLengthError;

  /// Secondary form button on edit-profile that triggers the same cancel/discard-check flow as the header back arrow.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editProfileCancelButtonLabel;

  /// Primary form button on edit-profile that submits the profile update.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editProfileSaveButtonLabel;

  /// Form-level error line under contact-sheet's fields when Full name/Phone is submitted empty (SCREENS.md §3.11, quoted), client-side before any request.
  ///
  /// In en, this message translates to:
  /// **'Required fields are not filled'**
  String get contactRequiredFieldsError;

  /// Form-level error line under contact-sheet's fields for a malformed phone (SCREENS.md §3.11, quoted), client-side before any request.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format'**
  String get contactInvalidPhoneError;

  /// Snackbar shown after contact-sheet successfully submits a message (SCREENS.md §3.11, quoted).
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully.'**
  String get contactSendSuccessToast;

  /// Form-level error line under contact-sheet's fields for ApiErrorCode.rateLimited (this endpoint is IP rate-limited at 5/minute).
  ///
  /// In en, this message translates to:
  /// **'Too many messages just now. Please try again in a minute.'**
  String get contactRateLimitedError;

  /// Form-level error line under contact-sheet's fields for ApiErrorCode.contactUnconfigured — nobody is configured to receive the message, so retrying cannot help.
  ///
  /// In en, this message translates to:
  /// **'The contact form isn\'t available right now. Please call the agent directly.'**
  String get contactUnconfiguredError;

  /// Form-level error line under contact-sheet's fields for ApiErrorCode.contactRelayFailed or any other unrecognized error code.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your message right now. Please try again.'**
  String get contactGenericErrorMessage;

  /// Form-level error line under contact-sheet's fields when submission fails with no server response (NetworkException).
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get contactNetworkErrorMessage;

  /// Title of contact-sheet (SCREENS.md §3.11, quoted).
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactSheetTitle;

  /// Semantics label on contact-sheet's close 'X' button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get contactSheetCloseLabel;

  /// Subtitle under contact-sheet's title (SCREENS.md §3.11, quoted).
  ///
  /// In en, this message translates to:
  /// **'We welcome all your concerns, issues, and suggestions. Feel free to get in touch with us at your most convenient time.'**
  String get contactSheetSubtitle;

  /// Field label on contact-sheet's full-name input (SCREENS.md §3.11, quoted).
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get contactFullNameFieldLabel;

  /// Field label on contact-sheet's phone input (SCREENS.md §3.11, quoted).
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhoneFieldLabel;

  /// Field label on contact-sheet's message textarea (SCREENS.md §3.11, quoted).
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactMessageFieldLabel;

  /// Placeholder inside contact-sheet's Message textarea (SCREENS.md §11), quoted from the mockup's own `<textarea class="ta glf" placeholder="I&rsquo;d like to view this apartment this week.">`. A sample of what to write rather than an instruction, so the empty textarea shows the expected length and tone; "apartment" is the sample's own noun (homeCategoryApartmentLabel's word), not a claim that the sheet only ever contacts about apartments. Straight apostrophe, matching every other string in this file.
  ///
  /// In en, this message translates to:
  /// **'I\'d like to view this apartment this week.'**
  String get contactMessageFieldHintText;

  /// Submit-button label on contact-sheet (SCREENS.md §3.11, quoted).
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get contactSendButtonLabel;

  /// Semantics label on each of RatingInput's five star buttons in the review sheet — 'N star'/'N stars' where N is that button's 1-based position, distinct from RatingStars' own read-only display which this widget deliberately does not share (see this file's doc comment).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} star} other{{count} stars}}'**
  String reviewsRatingInputStarLabel(int count);

  /// Nav-bar title on the leads-list screen (SCREENS.md §30).
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get leadsListScreenTitle;

  /// Nav-bar title on the leads-kanban screen (SCREENS.md §31).
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get leadsKanbanScreenTitle;

  /// Semantics label on leads-list's nav-row view-toggle icon button; switches to the Kanban view.
  ///
  /// In en, this message translates to:
  /// **'View as Kanban'**
  String get leadsToggleViewKanbanLabel;

  /// Semantics label on leads-kanban's nav-row view-toggle icon button; switches back to the list view.
  ///
  /// In en, this message translates to:
  /// **'View as list'**
  String get leadsToggleViewListLabel;

  /// Semantics label on the "+" add-lead circular button shared by leads-list's and leads-kanban's nav rows (leads_nav_actions.dart).
  ///
  /// In en, this message translates to:
  /// **'Add new lead'**
  String get leadsAddNewLeadLabel;

  /// Empty-state message on leads-list/leads-kanban when the caller's lead list is empty.
  ///
  /// In en, this message translates to:
  /// **'No leads yet.'**
  String get leadsEmptyMessage;

  /// Error message on leads-list/leads-kanban when the initial lead fetch fails. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your leads.'**
  String get leadsLoadErrorMessage;

  /// Empty-state message inside a single Kanban column (kanban_column.dart) that has no leads.
  ///
  /// In en, this message translates to:
  /// **'No leads in this stage yet.'**
  String get leadsEmptyColumnMessage;

  /// Failure note shown on a Kanban card (kanban_card.dart) whose most recent move attempt failed — apps/console's own copy, replicated verbatim per WORK_TAB_CONTRACT.md ruling 7.5.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move — try again.'**
  String get leadsCardMoveFailedMessage;

  /// Short form of leadsCardMoveFailedMessage for the tappable retry row on a Kanban card: the row pairs this with sharedRetryLabel, so the sentence must not also end in "try again". Use the full leadsCardMoveFailedMessage wherever the note is not actionable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move'**
  String get leadsCardMoveFailedLabel;

  /// Semantics label (screen-reader only) on the retry row of a Kanban card whose last move failed. {status} is the destination column's own label — one of the sharedLeadStatus* strings — so the reader hears where the retry would send the card.
  ///
  /// In en, this message translates to:
  /// **'Retry moving to {status}'**
  String leadsCardMoveRetrySemanticsLabel(String status);

  /// Nav-bar title on the create-lead screen (SCREENS.md §33).
  ///
  /// In en, this message translates to:
  /// **'Create Lead'**
  String get leadsCreateScreenTitle;

  /// Label on the Full name field, shared by create-lead and lead-detail's forms (lead_form_controls.dart's LeadTextField).
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get leadsFieldFullNameLabel;

  /// Label on the Phone field, shared by create-lead and lead-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get leadsFieldPhoneLabel;

  /// Label on the Email field, shared by create-lead and lead-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get leadsFieldEmailLabel;

  /// Label on the Budget field, shared by create-lead and lead-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get leadsFieldBudgetLabel;

  /// Label on the Commit (free-text notes) field, shared by create-lead and lead-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get leadsFieldCommitLabel;

  /// Label on the Source field, shared by create-lead and lead-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get leadsFieldSourceLabel;

  /// Hint text inside create-lead's Commit field before anything has been typed.
  ///
  /// In en, this message translates to:
  /// **'What are they looking for?'**
  String get leadsCreateCommitHint;

  /// Validation error under create-lead's Full name field when left empty — SCREENS.md §33's own quoted copy says "First name" even though the field label reads "Full name"; this mismatch is preserved rather than silently corrected (see create_lead_screen.dart's doc comment).
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get leadsCreateFullNameRequiredError;

  /// Validation error under create-lead's Phone field when left empty.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get leadsCreatePhoneRequiredError;

  /// Validation error under the Phone field (both create-lead and lead-detail) when the value doesn't match the UZ phone pattern.
  ///
  /// In en, this message translates to:
  /// **'Invalid Uzbekistan phone number'**
  String get leadsPhoneInvalidError;

  /// Validation error under lead-detail's Full name field when left empty — distinct wording from create-lead's own leadsCreateFullNameRequiredError; both are preserved verbatim rather than unified (see lead_detail_sheet.dart's doc comment).
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get leadsDetailFullNameRequiredError;

  /// Validation error under lead-detail's Budget field when the typed value isn't a parseable number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get leadsBudgetInvalidError;

  /// Section label above the lead-status chip group on create-lead/lead-detail (lead_form_controls.dart's LeadStatusField) — already uppercase in source, not run through a text-transform.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get leadsStatusFieldLabel;

  /// Default label on the call-time select field (lead_form_controls.dart's LeadDateTimeField), used by both kanban-move-sheet and lead-detail's conditional call-time row — already uppercase in source.
  ///
  /// In en, this message translates to:
  /// **'CALL TIME'**
  String get leadsCallTimeLabel;

  /// Placeholder text on the call-time field before a date/time has been chosen.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get leadsSelectDateLabel;

  /// Section label above the read-only Coworker field on create-lead/lead-detail (lead_form_controls.dart's LeadCoworkerField) — already uppercase in source.
  ///
  /// In en, this message translates to:
  /// **'COWORKER'**
  String get leadsCoworkerFieldLabel;

  /// Caption under the read-only Coworker field explaining why nothing typed there can be saved — see LeadCoworkerField's doc comment for the underlying wire-shape reason.
  ///
  /// In en, this message translates to:
  /// **'Assigning a coworker isn\'t available in this build yet.'**
  String get leadsCoworkerUnavailableNote;

  /// Cancel button label, shared by create-lead, lead-detail and kanban-move-sheet's own bespoke buttons (distinct widget from the sharedConfirmDialogCancelLabel used inside AlertDialog.adaptive confirms).
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get leadsCancelButtonLabel;

  /// Save button label, shared by create-lead, lead-detail and kanban-move-sheet.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get leadsSaveButtonLabel;

  /// Success toast after create-lead's Save completes.
  ///
  /// In en, this message translates to:
  /// **'Lead successfully created!'**
  String get leadsCreatedToastMessage;

  /// Error toast after a failed create-lead Save. {message} is the already-resolved failure description (leadsNoConnectionMessage/sharedGenericErrorMessage, or the server's own ApiErrorBody.message passed through verbatim — see lib/l10n/README.md's rule on never wrapping that field).
  ///
  /// In en, this message translates to:
  /// **'Error creating lead: {message}'**
  String leadsCreateErrorToastMessage(String message);

  /// Success toast after lead-detail's Save completes.
  ///
  /// In en, this message translates to:
  /// **'Lead successfully updated!'**
  String get leadsUpdatedToastMessage;

  /// Error toast after a failed lead-detail Save — same {message} shape as leadsCreateErrorToastMessage.
  ///
  /// In en, this message translates to:
  /// **'Error updating lead: {message}'**
  String leadsUpdateErrorToastMessage(String message);

  /// Success toast after lead-detail's Delete completes.
  ///
  /// In en, this message translates to:
  /// **'Lead successfully deleted!'**
  String get leadsDeletedToastMessage;

  /// Error toast after a failed lead-detail Delete — same {message} shape as leadsCreateErrorToastMessage.
  ///
  /// In en, this message translates to:
  /// **'Error deleting lead: {message}'**
  String leadsDeleteErrorToastMessage(String message);

  /// Fallback failure description used in every lead create/update/delete toast when the request never reached the server (NetworkException).
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get leadsNoConnectionMessage;

  /// The already-localized noun passed as confirmDelete's {subject} (shared/widgets/delete_confirm.dart) when deleting a lead from lead-detail — see that function's own doc comment for why the caller must supply an already-translated word. See GLOSSARY.md's "lead" entry for the term rendering.
  ///
  /// In en, this message translates to:
  /// **'lead'**
  String get leadsSubjectNoun;

  /// Semantics label on lead-detail's close ("X") icon button, top-right of the sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get leadsDetailCloseLabel;

  /// Label/tooltip on the call action in lead-detail's sheet header, beside the close ("X") button; hidden when the lead has no phone number. Same wording as agentsInfoCallButtonLabel but owned by the leads prefix.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get leadsCallButtonLabel;

  /// Semantics label (screen-reader only) on every tap-to-call target in the leads CRM: the detail sheet's header call button and the bold phone line on both the list row and the Kanban card. Mirrors listingAgentCallSemanticsLabel's shape, with the number itself rather than a name because that is the only identifier those two rows print.
  ///
  /// In en, this message translates to:
  /// **'Call {phone}'**
  String leadsCallSemanticsLabel(String phone);

  /// Error message shown inside lead-detail's sheet when the single-lead fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this lead.'**
  String get leadsDetailLoadErrorMessage;

  /// Destructive text button at the foot of lead-detail (agent-only — hidden for a coworker session).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get leadsDeleteLeadButtonLabel;

  /// Validation hint under kanban-move-sheet's Commit textarea while its length is below the minimum. {min} is the fixed minimum-length constant (10, SCREENS.md §34).
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters.'**
  String leadsCommitMinLengthError(int min);

  /// Title on kanban-move-sheet when the move destination is Need To Call Back.
  ///
  /// In en, this message translates to:
  /// **'Enter the next call-back time'**
  String get leadsCallbackSheetTitle;

  /// Title on kanban-move-sheet when the move destination is Rejected or Accepted.
  ///
  /// In en, this message translates to:
  /// **'Write briefly about the conversation'**
  String get leadsConversationSheetTitle;

  /// Hint text inside kanban-move-sheet's Commit textarea (the Rejected/Accepted note field). States the minimum length up front rather than surfacing it only after a failed save (leadsCommitMinLengthError).
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters'**
  String get leadsConversationHint;

  /// Title on leads-kanban's long-press "Move to…" action sheet listing the other four columns.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get leadsMoveToSheetTitle;

  /// Nav-bar title on the coworkers-list screen (SCREENS.md §35).
  ///
  /// In en, this message translates to:
  /// **'Coworkers'**
  String get coworkersListScreenTitle;

  /// Error message on coworkers-list when the roster fetch fails. No trailing period — byte-exact from the source string. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your coworkers'**
  String get coworkersLoadErrorMessage;

  /// Empty-state message on coworkers-list when the roster is empty.
  ///
  /// In en, this message translates to:
  /// **'No coworkers yet.'**
  String get coworkersEmptyMessage;

  /// Action label on coworkers-list's empty state (the FullWidthState under coworkersEmptyMessage), shown only when the session may actually create one — the same solo-realtor/coworker predicate that gates coworkersAddNewButtonLabel, since the server 403s the others. Drops that button's leading "+" and its "new", which read as list-header chrome rather than as the one way forward on an otherwise blank screen. Deliberately a second key with the same value as dashboardAddCoworkerButtonLabel rather than a shared one: the two live on different screens owned by different features, and consolidating them means renaming a shipped key plus its work_dashboard call site, which is out of scope for this pass — recorded here so the next integration sweep can fold both onto one shared key on purpose.
  ///
  /// In en, this message translates to:
  /// **'Add coworker'**
  String get coworkersEmptyStateActionLabel;

  /// Full-width button label on coworkers-list (SCREENS.md §35's own quoted copy, including the leading "+"); hidden for a solo agent or a coworker session that would 403 creating one.
  ///
  /// In en, this message translates to:
  /// **'+ Add new coworker'**
  String get coworkersAddNewButtonLabel;

  /// Ads-created count shown on a coworkers-list row's subtitle line — real data from CoworkerSummary.adsCreatedCount. The noun is "ads", matching SCREENS.md §35 and the mockup ('11 ads · …'), not "listings".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} ad} other{{count} ads}}'**
  String coworkersListingsCount(int count);

  /// Nav-bar title on the add-coworker screen (SCREENS.md §37).
  ///
  /// In en, this message translates to:
  /// **'Create coworker'**
  String get coworkersCreateScreenTitle;

  /// Error toast on add-coworker/coworker-detail when Save is tapped while an avatar photo is still mid-upload.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the photo to finish uploading.'**
  String get coworkersUploadWaitMessage;

  /// Pending-toast label shown while add-coworker's Save (the POST /coworkers call) is in flight — SCREENS.md §37's own quoted copy.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get coworkersUploadingToastLabel;

  /// Success toast after add-coworker's Save completes. No trailing punctuation — byte-exact from the source string.
  ///
  /// In en, this message translates to:
  /// **'Coworker successfully created'**
  String get coworkersCreatedToastMessage;

  /// Error toast after a failed add-coworker Save. {message} is the already-resolved failure description.
  ///
  /// In en, this message translates to:
  /// **'Error creating coworker: {message}'**
  String coworkersCreateErrorToastMessage(String message);

  /// Fallback failure description used in every coworker create/update/delete toast when the request never reached the server (NetworkException).
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get coworkersNoConnectionMessage;

  /// Fallback failure description used in every coworker create/update/delete toast for an unrecognized error. No trailing period — byte-exact from the source string, distinct from sharedGenericErrorMessage's own trailing period (that key is used instead where the source string does have one).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get coworkersGenericErrorMessage;

  /// Blocked-state message on add-coworker when reached by a signed-out session.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your team.'**
  String get coworkersSignInPromptMessage;

  /// Action-button label on add-coworker's signed-out blocked state; pushes the login screen.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get coworkersSignInActionLabel;

  /// Blocked-state message on add-coworker when reached by a non-agent (coworker) session.
  ///
  /// In en, this message translates to:
  /// **'Only agents can add coworkers.'**
  String get coworkersAgentOnlyMessage;

  /// Action-button label on add-coworker's/coworker-detail's blocked states; returns to coworkers-list.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get coworkersGoBackLabel;

  /// Blocked-state message on add-coworker when reached by a solo agent — the API's own literal copy (apps/api/src/routes/coworkers.js's solo_realtor error message), shown pre-emptively rather than only after a submit round-trip.
  ///
  /// In en, this message translates to:
  /// **'Solo agents don\'t have a team. Switch to an agency account to add coworkers.'**
  String get coworkersSoloAgentMessage;

  /// Semantics label on add-coworker's avatar upload control.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get coworkersAddPhotoLabel;

  /// Semantics label on coworker-detail's avatar upload control (agent-managed sessions only).
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get coworkersChangePhotoLabel;

  /// Label on the Full name field, shared by add-coworker and coworker-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get coworkersFieldFullNameLabel;

  /// Label on the Phone field, shared by add-coworker and coworker-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get coworkersFieldPhoneLabel;

  /// Label on the Email field, shared by add-coworker and coworker-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get coworkersFieldEmailLabel;

  /// Label on the Password field, shared by add-coworker and coworker-detail's forms.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get coworkersFieldPasswordLabel;

  /// Hint text inside add-coworker's Password field.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get coworkersPasswordHint;

  /// Hint text inside coworker-detail's Password field, where the password is optional on edit. Wording per the mockup's own placeholder.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep current'**
  String get coworkersPasswordHintKeepCurrent;

  /// Validation error under the Full name field (both add-coworker and coworker-detail) when left empty — SCREENS.md §37's own capitalisation ("Full Name", capital N) is preserved verbatim.
  ///
  /// In en, this message translates to:
  /// **'Full Name is required'**
  String get coworkersFullNameRequiredError;

  /// Validation error under add-coworker's Phone field when left empty — two distinct messages exist there (this one plus coworkersPhoneInvalidError), unlike coworker-detail's single combined message (see coworker_detail_screen.dart's doc comment).
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get coworkersPhoneRequiredError;

  /// Validation error under the Phone field — add-coworker's "wrong shape" message, and coworker-detail's single combined empty-or-wrong-shape message.
  ///
  /// In en, this message translates to:
  /// **'Invalid Uzbekistan phone number'**
  String get coworkersPhoneInvalidError;

  /// Validation error under the Email field (both add-coworker and coworker-detail) when left empty.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get coworkersEmailRequiredError;

  /// Validation error under add-coworker's Password field when left empty (password is required at create time, unlike coworker-detail's optional-on-edit field).
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get coworkersPasswordRequiredError;

  /// Validation error under the Password field (both add-coworker and coworker-detail) when a non-empty value is shorter than 6 characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get coworkersPasswordTooShortError;

  /// Cancel button label, shared by add-coworker and coworker-detail's own bespoke buttons.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coworkersCancelButtonLabel;

  /// Save button label, shared by add-coworker and coworker-detail.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coworkersSaveButtonLabel;

  /// Destructive Delete button label at the foot of coworker-detail (agent-managed sessions only).
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get coworkersDeleteButtonLabel;

  /// The already-localized noun passed as confirmDelete's {subject} (shared/widgets/delete_confirm.dart) when deleting from coworker-detail — see that function's own doc comment for why the caller must supply an already-translated word. See GLOSSARY.md's "coworker" entry for the term rendering.
  ///
  /// In en, this message translates to:
  /// **'coworker'**
  String get coworkersSubjectNoun;

  /// Nav-bar title on the coworker-detail screen (SCREENS.md §36).
  ///
  /// In en, this message translates to:
  /// **'Update coworker'**
  String get coworkersDetailScreenTitle;

  /// Terminal error message on coworker-detail when the id resolves 404 — permanent, no Retry offered alongside it.
  ///
  /// In en, this message translates to:
  /// **'This coworker is no longer available.'**
  String get coworkersNotFoundMessage;

  /// Error message on coworker-detail when the fetch fails for a transient (non-404) reason. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this coworker'**
  String get coworkersDetailLoadErrorMessage;

  /// Success toast after coworker-detail's Save completes.
  ///
  /// In en, this message translates to:
  /// **'Coworker successfully updated!'**
  String get coworkersUpdatedToastMessage;

  /// Error toast after a failed coworker-detail Save.
  ///
  /// In en, this message translates to:
  /// **'Error updating coworker: {message}'**
  String coworkersUpdateErrorToastMessage(String message);

  /// Success toast after coworker-detail's Delete completes.
  ///
  /// In en, this message translates to:
  /// **'Coworker successfully deleted!'**
  String get coworkersDeletedToastMessage;

  /// Error toast after a failed coworker-detail Delete.
  ///
  /// In en, this message translates to:
  /// **'Error deleting coworker: {message}'**
  String coworkersDeleteErrorToastMessage(String message);

  /// Caption on coworker-detail replacing Save/Delete for a coworker session viewing a sibling (read-only).
  ///
  /// In en, this message translates to:
  /// **'Only agents can edit or delete coworkers.'**
  String get coworkersReadOnlyNoteMessage;

  /// coworker_metrics.dart's coworkerActivityLabel: relative-time label for an activity timestamp under a minute old.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get coworkersActivityJustNow;

  /// coworkerActivityLabel's relative-time label for an activity timestamp under an hour old. "min" is an invariant abbreviation in the source English (never inflects with count), so only the "other" category is defined here.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} min ago}}'**
  String coworkersActivityMinutesAgo(int count);

  /// coworkerActivityLabel's relative-time label for an activity timestamp under a day old. "h" is an invariant abbreviation, same reasoning as coworkersActivityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} h ago}}'**
  String coworkersActivityHoursAgo(int count);

  /// coworkerActivityLabel's relative-time label for an activity timestamp exactly one calendar day old.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get coworkersActivityYesterday;

  /// coworkerActivityLabel's relative-time label for an activity timestamp two or more days old (one day old renders coworkersActivityYesterday instead, so this branch is never actually reached with count == 1 — only "other" is defined, matching the source's own unconditional "days" plural).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} days ago}}'**
  String coworkersActivityDaysAgo(int count);

  /// Header title on the dashboard screen (SCREENS.md §24), the agent Work tab's root.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get dashboardScreenHeaderTitle;

  /// Semantics label on dashboard's header bell icon button; pushes the notifications screen.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardNotificationsSemanticsLabel;

  /// Section-header title above the Coworker statistics bar-chart-and-list section on dashboard.
  ///
  /// In en, this message translates to:
  /// **'Coworker statistics'**
  String get dashboardCoworkerStatisticsSectionTitle;

  /// Group-label heading above dashboard's three Workspace quick-nav rows (My Ads/Leads/Coworkers).
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get dashboardWorkspaceGroupLabel;

  /// Panel-header title on dashboard's "Ads statistics" area chart.
  ///
  /// In en, this message translates to:
  /// **'Ads statistics'**
  String get dashboardAdsStatisticsTitle;

  /// Retry-card message inside the Ads statistics panel when the series fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load ad statistics'**
  String get dashboardAdsStatisticsLoadErrorMessage;

  /// Message inside the Ads statistics panel when the series fetch succeeds but returns zero buckets for the selected range.
  ///
  /// In en, this message translates to:
  /// **'No data for this range.'**
  String get dashboardNoDataForRangeMessage;

  /// Legend-dot label under the Ads statistics chart for the "Created" series.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get dashboardLegendCreated;

  /// Legend-dot label under the Ads statistics chart for the "Sold" series.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get dashboardLegendSold;

  /// Semantics label wrapping dashboard's Ads statistics CustomPaint chart, which paints two bare paths and otherwise exposes nothing to a screen reader. {range} is the panel's own caption (dashboardCaptionDaysRange and friends); {created}/{sold} are the totals summed over the plotted buckets.
  ///
  /// In en, this message translates to:
  /// **'Ads statistics, {range}: {created} created, {sold} sold'**
  String dashboardChartSemanticsLabel(String range, int created, int sold);

  /// Ads statistics panel's date-range caption for a single hour-granularity bucket. {hour} is an already-formatted "HH:00" string, passed through untranslated (a formatted time, not UI wording).
  ///
  /// In en, this message translates to:
  /// **'Hour {hour}'**
  String dashboardCaptionHour(String hour);

  /// Ads statistics panel's date-range caption for a multi-bucket hour-granularity series. {start}/{end} are already-formatted "HH:00" strings.
  ///
  /// In en, this message translates to:
  /// **'Hours {start}–{end}'**
  String dashboardCaptionHoursRange(String start, String end);

  /// Ads statistics panel's date-range caption for a single day-granularity bucket that stays within the current calendar month. {day} is a bare day-of-month number, not a pluralizing count.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dashboardCaptionDay(int day);

  /// Ads statistics panel's date-range caption for a multi-bucket day-granularity series that stays within one calendar month. {start}/{end} are bare day-of-month numbers.
  ///
  /// In en, this message translates to:
  /// **'Days {start}–{end}'**
  String dashboardCaptionDaysRange(int start, int end);

  /// Ads statistics panel's caption when the "All" chip is selected: the tiles above genuinely report all time, but the series endpoint has no all-time mode so live_dashboard_repository.dart rewrites the request to this month (documented there). {range} is the ordinary caption this wraps — dashboardCaptionDaysRange and friends — so the panel names the plotted span AND admits it is narrower than the chip.
  ///
  /// In en, this message translates to:
  /// **'{range} · chart shows this month'**
  String dashboardCaptionAllTimeChartNote(String range);

  /// Retry-card message inside the Coworker statistics section when its fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load coworker statistics'**
  String get dashboardCoworkerStatisticsLoadErrorMessage;

  /// Empty-state message inside the Coworker statistics section when the caller has no coworkers.
  ///
  /// In en, this message translates to:
  /// **'No coworkers yet.'**
  String get dashboardNoCoworkersMessage;

  /// Action button inside dashboard's empty Coworker statistics panel, shown only for an AGENCY realtor (a solo realtor never sees the panel at all, since the server 403s their add-coworker call). Pushes the same create-coworker screen as coworkersAddNewButtonLabel, whose "+ " prefix and "new" this drops because it sits in an empty state rather than a list header.
  ///
  /// In en, this message translates to:
  /// **'Add coworker'**
  String get dashboardAddCoworkerButtonLabel;

  /// Legend-dot label under the Coworker statistics bar chart for the "Ads count" series.
  ///
  /// In en, this message translates to:
  /// **'Ads count'**
  String get dashboardLegendAdsCount;

  /// Legend-dot label under the Coworker statistics bar chart for the "Lead count" series.
  ///
  /// In en, this message translates to:
  /// **'Lead count'**
  String get dashboardLegendLeadCount;

  /// Legend-dot label under the Coworker statistics bar chart for the "Sale count" series.
  ///
  /// In en, this message translates to:
  /// **'Sale count'**
  String get dashboardLegendSaleCount;

  /// Semantics label on one coworker's three-bar group in the Coworker statistics chart, which paints three unlabelled lengths and exposes nothing to a screen reader. {name} is the coworker's own name as printed in the table below the chart.
  ///
  /// In en, this message translates to:
  /// **'{name}: {ads} ads, {leads} leads, {sales} sales'**
  String dashboardCoworkerBarsSemanticsLabel(
    String name,
    int ads,
    int leads,
    int sales,
  );

  /// Column-header label above the Coworker statistics list's coworker-name column. Stored sentence case: _HeaderCell uppercases at the call site (`.tbl__h{text-transform:uppercase}`), the same rule _StatTile's label follows, so the ru/uz values stay human-readable.
  ///
  /// In en, this message translates to:
  /// **'Coworkers'**
  String get dashboardHeaderCoworkers;

  /// Column-header label above the Coworker statistics list's Ads figures. Stored sentence case: _HeaderCell uppercases at the call site (`.tbl__h{text-transform:uppercase}`), the same rule _StatTile's label follows, so the ru/uz values stay human-readable.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get dashboardHeaderAds;

  /// Column-header label above the Coworker statistics list's Leads figures. Stored sentence case: _HeaderCell uppercases at the call site (`.tbl__h{text-transform:uppercase}`), the same rule _StatTile's label follows, so the ru/uz values stay human-readable.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get dashboardHeaderLeads;

  /// Column-header label above the Coworker statistics list's Sales figures. Stored sentence case: _HeaderCell uppercases at the call site (`.tbl__h{text-transform:uppercase}`), the same rule _StatTile's label follows, so the ru/uz values stay human-readable.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get dashboardHeaderSales;

  /// Label on dashboard's 2×2 stat-tile grid, first tile.
  ///
  /// In en, this message translates to:
  /// **'Ads created'**
  String get dashboardTileAdsCreatedLabel;

  /// Label on dashboard's 2×2 stat-tile grid, second tile.
  ///
  /// In en, this message translates to:
  /// **'Ads sold'**
  String get dashboardTileAdsSoldLabel;

  /// Label on dashboard's 2×2 stat-tile grid, third tile.
  ///
  /// In en, this message translates to:
  /// **'Active leads'**
  String get dashboardTileActiveLeadsLabel;

  /// Label on dashboard's 2×2 stat-tile grid, fourth tile (tappable — pushes coworkers-list).
  ///
  /// In en, this message translates to:
  /// **'Coworkers'**
  String get dashboardTileCoworkersLabel;

  /// Subtitle on dashboard's Coworkers stat tile, hinting that the tile is tappable.
  ///
  /// In en, this message translates to:
  /// **'tap to manage'**
  String get dashboardTileTapToManageSubtitle;

  /// Subtitle on dashboard's Ads sold stat tile, hinting that the tile is tappable. "view" rather than dashboardTileTapToManageSubtitle's "manage" because the tap opens My Ads pre-filtered to the sold stage — a read-only shortcut, not a management screen.
  ///
  /// In en, this message translates to:
  /// **'tap to view'**
  String get dashboardTileTapToViewSubtitle;

  /// Subtitle text on the Ads created/Ads sold stat tiles when the All time-range filter is selected.
  ///
  /// In en, this message translates to:
  /// **'all time'**
  String get dashboardRangeSubtitleAll;

  /// Subtitle text on the Ads created/Ads sold stat tiles when the This month time-range filter is selected.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get dashboardRangeSubtitleThisMonth;

  /// Subtitle text on the Ads created/Ads sold stat tiles when the This week time-range filter is selected.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get dashboardRangeSubtitleThisWeek;

  /// Subtitle text on the Ads created/Ads sold stat tiles when the Today time-range filter is selected.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get dashboardRangeSubtitleToday;

  /// Subtitle on dashboard's Active leads stat tile: how many leads are due (or overdue) a callback today, with subject-verb agreement on the count ("1 needs"/"N need") — this dual form already existed in the pre-extraction Dart, unlike dashboardWorkspaceLeadsSubtitle's identical concept, which is now routed through this same message (see dashboard_workspace_links.dart).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} needs a call back} other{{count} need a call back}}'**
  String dashboardCallbackSubtitle(int count);

  /// Chip label on dashboard's time-range selector for StatisticsFilter.all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dashboardFilterLabelAll;

  /// Chip label on dashboard's time-range selector for StatisticsFilter.thisMonth — also the default-selected filter.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardFilterLabelThisMonth;

  /// Chip label on dashboard's time-range selector for StatisticsFilter.thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashboardFilterLabelThisWeek;

  /// Chip label on dashboard's time-range selector for StatisticsFilter.today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardFilterLabelToday;

  /// Row title on dashboard's Workspace quick-nav list, first row; pushes my-listings.
  ///
  /// In en, this message translates to:
  /// **'My Ads'**
  String get dashboardWorkspaceMyAdsRowTitle;

  /// Row title on dashboard's Workspace quick-nav list, second row; pushes leads-list.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get dashboardWorkspaceLeadsRowTitle;

  /// Row title on dashboard's Workspace quick-nav list, third row; pushes coworkers-list.
  ///
  /// In en, this message translates to:
  /// **'Coworkers'**
  String get dashboardWorkspaceCoworkersRowTitle;

  /// Subtitle on dashboard's "My Ads" Workspace row: total listing count and how many are drafts. The pre-existing Dart interpolation this replaces always renders both nouns plural regardless of count (dashboard_screen_test.dart's own fixture pins '4 listings · 1 drafts', not '1 draft') — unlike homeAgentAdsCount's identical-looking bug, this one is preserved byte-identical rather than fixed with an ICU plural, since an existing test already froze the unconditional-plural wording; flagged in this run's report rather than silently changed.
  ///
  /// In en, this message translates to:
  /// **'{listings} listings · {drafts} drafts'**
  String dashboardWorkspaceMyAdsSubtitle(int listings, int drafts);

  /// Subtitle on dashboard's "Leads" Workspace row: total active-lead count and how many need a callback today. Deliberately **not** routed through dashboardCallbackSubtitle's singular/plural verb agreement ("1 needs"/"N need") even though the two concepts are otherwise identical — the pre-extraction Dart here always rendered the plural verb "need" regardless of count (dashboard_screen_test.dart's own fixture pins '3 active · 1 need a call back', not '1 needs'), unlike dashboardCallbackSubtitle's stat tile which already had the dual form. Preserved byte-identical rather than "fixed", per lib/l10n/README.md's rule to move strings, not silently improve them — flagged in this run's report rather than corrected here.
  ///
  /// In en, this message translates to:
  /// **'{active} active · {dueToday} need a call back'**
  String dashboardWorkspaceLeadsSubtitle(int active, int dueToday);

  /// Subtitle on dashboard's "Coworkers" Workspace row: total coworker count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} person} other{{count} people}}'**
  String dashboardWorkspaceCoworkersSubtitle(int count);

  /// Nav-bar title on the notifications screen (SCREENS.md §22).
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsScreenTitle;

  /// Error message on notifications when the feed fetch fails. Paired with sharedRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your notifications.'**
  String get notificationsLoadErrorMessage;

  /// Header action on notifications that clears every row's unread dot.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllReadLabel;

  /// Toast confirming the notifications header's Mark all read action succeeded.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked read'**
  String get notificationsMarkedAllReadToastMessage;

  /// Pending toast shown while 'Mark all read' is in flight on the notifications screen — the first state of LaCasaToast.run's pending → success/error sequence.
  ///
  /// In en, this message translates to:
  /// **'Marking all read'**
  String get notificationsMarkAllReadPendingLabel;

  /// Error toast when 'Mark all read' fails on the notifications screen. Previously the failure produced no feedback at all — the success toast fired unconditionally and the exception escaped as an unhandled zone error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark your notifications read.'**
  String get notificationsMarkAllReadErrorMessage;

  /// Empty-state message on notifications when the feed is empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmptyMessage;

  /// Second line of the notifications empty state, saying what the feed is for instead of leaving 'No notifications yet.' to stand alone.
  ///
  /// In en, this message translates to:
  /// **'New leads, ad approvals and publish results show up here.'**
  String get notificationsEmptyStateDetailMessage;

  /// Action-pill label on the notifications empty state, re-fetching the feed. The only useful action on a feed the user cannot add to themselves.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get notificationsEmptyStateActionLabel;

  /// Screen-level message shown instead of the feed when a signed-in buyer reaches the notifications screen by a deep link or a stale back-stack entry — GET /notifications 403s for a non-agent, so the feed can only ever fail for them.
  ///
  /// In en, this message translates to:
  /// **'Notifications are available to agents only.'**
  String get notificationsAgentOnlyMessage;

  /// Screen-level message shown instead of the feed when a signed-out visitor reaches the notifications screen; paired with the shared 'Sign in' action.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your notifications.'**
  String get notificationsSignInPromptMessage;

  /// Action label on the notifications screen's agent-only state, popping back to wherever the user came from.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get notificationsGoBackLabel;

  /// Semantics label on an unread notification row (notification_row.dart). {title} is the notification's own already-authored title text (server/fixture content, not app UI copy), passed through untranslated — only the ", unread" suffix is this app's own wording.
  ///
  /// In en, this message translates to:
  /// **'{title}, unread'**
  String notificationsUnreadSemanticsLabel(String title);

  /// live_notifications_repository.dart's _relativeTime: relative-time label for a notification under a minute old. Mirrors coworkersActivityJustNow's identical copy in a different feature (both format the same kind of relative timestamp independently).
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsRelativeJustNow;

  /// _relativeTime's relative-time label for a notification under an hour old — same invariant-abbreviation reasoning as coworkersActivityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} min ago}}'**
  String notificationsRelativeMinutesAgo(int count);

  /// _relativeTime's relative-time label for a notification under a day old — same invariant-abbreviation reasoning as coworkersActivityHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} h ago}}'**
  String notificationsRelativeHoursAgo(int count);

  /// _relativeTime's relative-time label for a notification exactly one calendar day old.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationsRelativeYesterday;

  /// _relativeTime's relative-time label for a notification two or more days old — same "other"-only reasoning as coworkersActivityDaysAgo (the day==1 case renders notificationsRelativeYesterday instead, so this branch never actually receives count == 1).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} days ago}}'**
  String notificationsRelativeDaysAgo(int count);

  /// Nav-bar title on the messages screen (SCREENS.md §23).
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesScreenTitle;

  /// Heading of the messages screen's permanent placeholder banner — the first half of SCREENS.md §23's quoted copy, split out so it can carry the mockup's `.empty h3` weight.
  ///
  /// In en, this message translates to:
  /// **'Messaging is coming soon'**
  String get messagesComingSoonTitle;

  /// Paragraph of the messages screen's permanent placeholder banner — SCREENS.md §23's second sentence plus the mockup's `.empty p` follow-up (messaging is intentionally never implemented in this build).
  ///
  /// In en, this message translates to:
  /// **'For now, contact leads by phone. Every lead card carries a tap-to-call number.'**
  String get messagesComingSoonBody;

  /// Label on the messages screen's one action — a pill that routes to the Leads list, where the tap-to-call numbers live.
  ///
  /// In en, this message translates to:
  /// **'Open Leads'**
  String get messagesOpenLeadsAction;

  /// Nav-bar title on the connected-accounts screen (SCREENS.md §21).
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccountsScreenTitle;

  /// Title text beside connected-accounts' read-only Instagram status switch.
  ///
  /// In en, this message translates to:
  /// **'Create Instagram post'**
  String get connectedAccountsInstagramToggleTitle;

  /// Subtitle under connected-accounts' Instagram channel header, explaining what the read-only status switch reflects.
  ///
  /// In en, this message translates to:
  /// **'Status — on when at least one account is linked'**
  String get connectedAccountsInstagramToggleSubtitle;

  /// Title text beside connected-accounts' read-only Telegram status switch.
  ///
  /// In en, this message translates to:
  /// **'Create Telegram post'**
  String get connectedAccountsTelegramToggleTitle;

  /// Subtitle under connected-accounts' Telegram channel header, explaining what the read-only status switch reflects.
  ///
  /// In en, this message translates to:
  /// **'Status — on when a channel is linked'**
  String get connectedAccountsTelegramToggleSubtitle;

  /// Title text beside connected-accounts' read-only YouTube status switch.
  ///
  /// In en, this message translates to:
  /// **'Create Youtube post'**
  String get connectedAccountsYoutubeToggleTitle;

  /// Title text beside connected-accounts' read-only Threads status switch, which is permanently off (ruling 7.10's treatment). Same shape as connectedAccountsYoutubeToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Threads post'**
  String get connectedAccountsThreadsToggleTitle;

  /// Title text beside connected-accounts' read-only Facebook Marketplace status switch, which is permanently off.
  ///
  /// In en, this message translates to:
  /// **'Create Facebook Marketplace post'**
  String get connectedAccountsFacebookMarketplaceToggleTitle;

  /// Title text beside connected-accounts' read-only X status switch, which is permanently off.
  ///
  /// In en, this message translates to:
  /// **'Create X post'**
  String get connectedAccountsXToggleTitle;

  /// Title text beside connected-accounts' read-only LinkedIn status switch, which is permanently off.
  ///
  /// In en, this message translates to:
  /// **'Create LinkedIn post'**
  String get connectedAccountsLinkedinToggleTitle;

  /// Retry-card message on connected-accounts' Instagram section when the account-list fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your Instagram accounts.'**
  String get connectedAccountsInstagramLoadErrorMessage;

  /// Fallback name fed to AgentAvatar for an Instagram account card whose username is unavailable — the product name itself, not translated word-for-word but included for consistent extraction.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get connectedAccountsAvatarFallbackName;

  /// Pending-toast label while an Instagram account's Disconnect action is in flight.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get connectedAccountsDisconnectingToastLabel;

  /// Success toast after an Instagram account's Disconnect action completes.
  ///
  /// In en, this message translates to:
  /// **'Instagram account disconnected.'**
  String get connectedAccountsDisconnectedToastMessage;

  /// Fallback noun used in connectedAccountsDisconnectSemanticsLabel when the account has no username to name it by.
  ///
  /// In en, this message translates to:
  /// **'Instagram account'**
  String get connectedAccountsFallbackAccountName;

  /// Semantics label on an Instagram account card's Disconnect button. {name} is either the account's own @username (data, untranslated) or connectedAccountsFallbackAccountName's text.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {name}'**
  String connectedAccountsDisconnectSemanticsLabel(String name);

  /// Visible button text on an Instagram account card's Disconnect button.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get connectedAccountsDisconnectButtonLabel;

  /// Optional stat chip on an Instagram account card — the label word never inflects with {count} (a fixed "Posts N" tag, not a counted-noun phrase).
  ///
  /// In en, this message translates to:
  /// **'Posts {count}'**
  String connectedAccountsPostsStatLabel(int count);

  /// Optional stat chip on an Instagram account card — same fixed-label shape as connectedAccountsPostsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Followers {count}'**
  String connectedAccountsFollowersStatLabel(int count);

  /// Optional stat chip on an Instagram account card — same fixed-label shape as connectedAccountsPostsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Following {count}'**
  String connectedAccountsFollowingStatLabel(int count);

  /// Both the visible text and the semantics label on connected-accounts' full-width Connect Instagram button.
  ///
  /// In en, this message translates to:
  /// **'Connect Instagram'**
  String get connectedAccountsConnectButtonLabel;

  /// Success toast after Connect Instagram successfully hands the OAuth URL to the device's browser. Deliberately does not claim the connection itself completed — see instagram_accounts_section.dart's doc comment for why §21's original "connected!" copy isn't reachable in this build.
  ///
  /// In en, this message translates to:
  /// **'Opening Instagram sign-in in your browser.'**
  String get connectedAccountsOpeningBrowserToastMessage;

  /// Success toast (clipboard fallback) after Connect Instagram when no browser could be launched on this device — the OAuth URL was copied instead.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your browser — Instagram sign-in link copied instead. Paste it into your browser to connect.'**
  String get connectedAccountsLinkCopiedToastMessage;

  /// Error toast when Connect Instagram fails outright (couldn't even fetch the sign-in link) — SCREENS.md §21's spec copy verbatim, reused for the closest real failure this OAuth-by-browser flow has.
  ///
  /// In en, this message translates to:
  /// **'Instagram connection failed — please try again.'**
  String get connectedAccountsConnectionFailedToastMessage;

  /// Row text on connected-accounts' Telegram section when at least one channel is connected — count comes from AuthUser.tgChatIds.length.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} channel connected} other{{count} channels connected}}'**
  String connectedAccountsTelegramChannelsConnected(int count);

  /// Row text on connected-accounts' Telegram section when tgChatIds is empty — a distinct literal, not the zero-case of connectedAccountsTelegramChannelsConnected's plural.
  ///
  /// In en, this message translates to:
  /// **'No Telegram channels connected'**
  String get connectedAccountsTelegramNoChannelsMessage;

  /// Label on connected-accounts' permanently-disabled YouTube "Add account" button.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get connectedAccountsYoutubeAddAccountLabel;

  /// Label on connected-accounts' permanently-disabled YouTube "Sign out" button.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get connectedAccountsYoutubeSignOutLabel;

  /// Semantics label on each disabled YouTube button — wraps the button's own visible label (connectedAccountsYoutubeAddAccountLabel/connectedAccountsYoutubeSignOutLabel) with a reason it can't be tapped.
  ///
  /// In en, this message translates to:
  /// **'{label} (unavailable in this build)'**
  String connectedAccountsUnavailableSemanticsSuffix(String label);

  /// Caption under connected-accounts' YouTube section explaining why its controls are disabled.
  ///
  /// In en, this message translates to:
  /// **'Beta — not available in this build.'**
  String get connectedAccountsYoutubeBetaNoteMessage;

  /// `.lrow__s` sub-line under connected-accounts' Threads channel header, explaining why the section carries no connect control at all. Same sentence as listingEditorThreadsUnavailableHint but a separate key for a separate surface — the same two-key split connectedAccountsYoutubeBetaNoteMessage and listingEditorYoutubeUnavailableHint already use.
  ///
  /// In en, this message translates to:
  /// **'Threads posting needs a Threads profile linked to an Instagram professional account — this build never requests that permission.'**
  String get connectedAccountsThreadsUnavailableNoteMessage;

  /// `.lrow__s` sub-line under connected-accounts' Facebook Marketplace channel header. Same two-key split as connectedAccountsThreadsUnavailableNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Facebook Marketplace has no compliant automation path on any platform — its listings have to be posted by hand.'**
  String get connectedAccountsFacebookMarketplaceUnavailableNoteMessage;

  /// `.lrow__s` sub-line under connected-accounts' X channel header. Same two-key split as connectedAccountsThreadsUnavailableNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'X posting needs its own X API app on a paid write tier — neither is set up in this build.'**
  String get connectedAccountsXUnavailableNoteMessage;

  /// `.lrow__s` sub-line under connected-accounts' LinkedIn channel header. Same two-key split as connectedAccountsThreadsUnavailableNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn posting needs an approved LinkedIn Marketing API app — this build has no LinkedIn credentials.'**
  String get connectedAccountsLinkedinUnavailableNoteMessage;

  /// Semantics label on a read-only channel-status switch (Instagram/Telegram/YouTube) when it reads on/connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedAccountsConnectedStatusLabel;

  /// Semantics label on a read-only channel-status switch when it reads off/not connected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get connectedAccountsNotConnectedStatusLabel;

  /// Hint under connected-accounts' Connect Instagram button, explaining why the sign-in leaves the app.
  ///
  /// In en, this message translates to:
  /// **'Opens your system browser — Meta does not permit OAuth inside an in-app WebView.'**
  String get connectedAccountsInstagramBrowserHint;

  /// Footer hint at the bottom of connected-accounts, explaining why OLX has no channel block of its own. Facebook Marketplace was named here too until it gained its own visibly-disabled block (ruling 7.10's treatment) — do not re-add it.
  ///
  /// In en, this message translates to:
  /// **'OLX has no persistent account to connect — OLX cross-posting runs from the desktop app only.'**
  String get connectedAccountsOtherChannelsHint;

  /// Section label above kanban-move-sheet Commit textarea (the Rejected/Accepted note field) — already uppercase in source, a different widget from the leadsFieldCommitLabel title-case label used on create-lead/lead-detail forms.
  ///
  /// In en, this message translates to:
  /// **'COMMIT'**
  String get leadsCommitFieldUppercaseLabel;

  /// Sheet title on language-sheet (SCREENS.md §3.20) — quoted character for character by the spec. Distinct from settingsLanguageRowTitle/profileAgentLanguageRowTitle/profileBuyerLanguageRowTitle/profileSignedOutLanguageRowTitle, which are the nav rows that open this sheet, not the sheet's own header.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSheetTitle;

  /// Semantics label on language-sheet's dismiss 'X' — same per-sheet-owned pattern as contactSheetCloseLabel/reviewsSheetCloseLabel/leadsDetailCloseLabel, not the shared component keys (sharedMediaSourceCloseLabel/sharedNavRowCloseLabel).
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get languageSheetCloseLabel;

  /// Semantics label on photo-gallery's previous-photo round button in the top overlay (mockup `.gv__top` `data-gal-step`). Disabled on the first photo.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get galleryPreviousPhotoSemanticsLabel;

  /// Semantics label on photo-gallery's next-photo round button in the top overlay (mockup `.gv__top` `data-gal-step`). Disabled on the last photo.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get galleryNextPhotoSemanticsLabel;

  /// Persistent `.hint` line under contact-sheet's Phone field, stating the validity rule before a failed submit rather than only after one.
  ///
  /// In en, this message translates to:
  /// **'Uzbekistan numbers only — +998 and nine digits.'**
  String get contactPhoneFieldHint;

  /// Persistent `.hint` line under create-lead's Phone field. Deliberately a separate key from contactPhoneFieldHint despite the identical English: the two screens own their own copy, and a future wording change to one must not silently move the other.
  ///
  /// In en, this message translates to:
  /// **'Uzbekistan numbers only — +998 and nine digits.'**
  String get leadsPhoneFormatHint;

  /// Placeholder on an unset Min/Max price field, and the label of the leading "clear" row inside its option-picker sheet — the price counterpart to filterCityAnyOptionLabel/filterDistrictAnyOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get filterPriceAnyOptionLabel;

  /// Trailing count on agent-profile's "Ads List" section header — the `.sec` row's muted `.link` slot, replacing the old parenthesized-heading form. Russian inflects on the count, so it is a plural message there; Uzbek does not inflect (CLDR other-only) and English reads the same at every count.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String agentsAdsGridActiveCountLabel(int count);

  /// The `.lead__p` paragraph under permissions-primer's "Allow La Casa to…" heading.
  ///
  /// In en, this message translates to:
  /// **'Two permissions, asked once. You can change either of them later in Settings.'**
  String get permissionsPrimerLeadBody;

  /// The `.lead__p` paragraph under login's "Welcome back" heading. Deliberately its own key rather than reusing the character-identical profileSignedOutPromptMessage: the two screens own their own copy.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save listings, message agents, and manage your business.'**
  String get authLoginLeadBody;

  /// The `.lead__p` paragraph under register's "Create your account" heading, explaining what a realtor account adds. "Work" is the same tab name as navTabWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Browsing, saving and messaging work on any account. A realtor account adds the Work tab — listings, leads and publishing.'**
  String get authRegisterLeadBody;

  /// Placeholder inside register's Full name field. A person's name, so it is the same in all three locales — the mockup's own sample value.
  ///
  /// In en, this message translates to:
  /// **'Dilnoza Yusupova'**
  String get authRegisterFullNameHint;

  /// Placeholder inside the Email field on BOTH login and register (the mockup shows the same one on each). An address literal, identical in all three locales.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// `.lrow__s` sub-line under profile-signed-out's Contact Us row.
  ///
  /// In en, this message translates to:
  /// **'Questions, issues and suggestions'**
  String get profileSignedOutContactUsRowSubtitle;

  /// `.lrow__s` sub-line under profile-agent's Edit Profile row — what the screen behind it edits.
  ///
  /// In en, this message translates to:
  /// **'Avatar, name, phone, email'**
  String get profileAgentEditProfileRowSubtitle;

  /// `.lrow__s` sub-line under profile-agent's Connected Accounts row. Three product names, so identical in all three locales. A static descriptor, deliberately not a live "n connected" count — this screen watches no connected-accounts provider.
  ///
  /// In en, this message translates to:
  /// **'Instagram, Telegram, YouTube'**
  String get profileAgentConnectedAccountsRowSubtitle;

  /// `.lrow__s` sub-line under profile-agent's Settings row.
  ///
  /// In en, this message translates to:
  /// **'Language, notifications, about'**
  String get profileAgentSettingsRowSubtitle;

  /// `.lrow__s` sub-line under profile-agent's Messages row — the screen exists but has no server-backed conversation list yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get profileAgentMessagesRowSubtitle;

  /// `.lrow__s` sub-line under profile-buyer's Update Profile row.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, email, password'**
  String get profileBuyerUpdateProfileRowSubtitle;

  /// `.lrow__s` sub-line under profile-buyer's Register as Agent row — says where the tap goes, since it leaves the app.
  ///
  /// In en, this message translates to:
  /// **'Opens a Google Form in your browser'**
  String get profileBuyerRegisterAsAgentRowSubtitle;

  /// `.lrow__s` sub-line under settings' Connected Accounts row — the same static channel list profileAgentConnectedAccountsRowSubtitle carries, kept as a separate key because the two screens own their own copy.
  ///
  /// In en, this message translates to:
  /// **'Instagram, Telegram, YouTube'**
  String get settingsConnectedAccountsRowSubtitle;

  /// `.lrow__s` sub-line under settings' Logout row while it is at rest; settingsLoggingOutLabel replaces it while the sign-out is in flight.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again'**
  String get settingsLogoutRowSubtitle;

  /// `.hint` line under edit-profile's Password field: the field is optional on edit and only validated when filled in.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters. Only needed if you are changing it.'**
  String get editProfilePasswordHelper;

  /// The `.endnote` caption under LoadMoreFooter's spinner (shared/widgets/load_more_footer.dart) — a scroll-triggered page fetch, so the sentinel says what it is doing rather than spinning unlabelled.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get sharedLoadMoreLoadingLabel;

  /// The floating `.kbhint` pill above leads-kanban's tab bar, naming the (otherwise invisible) gesture that moves a card between columns.
  ///
  /// In en, this message translates to:
  /// **'Long-press a card to move it'**
  String get leadsKanbanLongPressHint;

  /// The red `.kcard__flag` pill on a leads-kanban card in "Need to Call Back". {when} is an already-formatted date/time (Formatters.date), not a value that inflects the sentence.
  ///
  /// In en, this message translates to:
  /// **'Call back {when}'**
  String leadsCallBackFlagLabel(String when);

  /// Placeholder inside create-lead's optional Email and Budget fields — the mockup labels both that way rather than showing a sample value.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get leadsOptionalFieldHint;

  /// The `.sh__p` context line under kanban-move-sheet's "Move to…" title, naming which lead is being moved and where it currently sits. {status} is an already-localized LeadStatus label.
  ///
  /// In en, this message translates to:
  /// **'{name} is in {status}.'**
  String leadsMoveToContextLine(String name, String status);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
