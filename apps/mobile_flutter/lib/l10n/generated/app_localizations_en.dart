// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsNavBackLabel => 'Back';

  @override
  String get settingsLanguageRowTitle => 'Language';

  @override
  String get settingsConnectedAccountsRowTitle => 'Connected Accounts';

  @override
  String get settingsAboutRowTitle => 'About';

  @override
  String settingsAboutRowSubtitle(String version) {
    return 'Version $version';
  }

  @override
  String settingsAboutToastMessage(String appName, String version) {
    return '$appName $version';
  }

  @override
  String get settingsSessionGroupLabel => 'Session';

  @override
  String get settingsLogoutRowTitle => 'Logout';

  @override
  String get settingsLoggingOutLabel => 'Signing out…';

  @override
  String get settingsSignOutTokenNotClearedMessage =>
      'Signed out, but the saved session couldn\'t be removed from this device. Sign out again, or remove the app, before handing it on.';

  @override
  String get settingsNotificationsRowTitle => 'Notifications';

  @override
  String get settingsNotificationsRowSubtitle =>
      'Not sent yet — push notifications aren\'t wired up in this build.';

  @override
  String get settingsNotificationsToggleLabel => 'Notifications toggle';

  @override
  String get homeLocationPillLabel => 'Tashkent, Uzbekistan';

  @override
  String homeNotificationsBellSemanticLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count unread',
      one: 'Notifications, $count unread',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchIconSemanticLabel => 'Search';

  @override
  String get homeAgentPitchHeading => 'Are you a real estate agent?';

  @override
  String get homeAgentPitchSubtitle =>
      'Manage your listings, leads and team in one app.';

  @override
  String get homeAgentPitchButtonLabel => 'Get Started';

  @override
  String get homeCategoryAllLabel => 'All';

  @override
  String get homeCategoryApartmentLabel => 'Apartment';

  @override
  String get homeCategoryHouseLabel => 'House';

  @override
  String get homeCategoryOfficeLabel => 'Office';

  @override
  String get homeCategoryRetailLabel => 'Retail';

  @override
  String homeCategoryChipSemanticsLabel(String category) {
    return 'Show $category listings';
  }

  @override
  String get homeExploreNearbySectionTitle => 'Explore Nearby';

  @override
  String get homeFeaturedListingsSectionTitle => 'Featured Listings';

  @override
  String get homeFeaturedListingsViewAllLabel => 'View all';

  @override
  String get homeFeaturedListingsRetryMessage => 'Couldn\'t load listings';

  @override
  String get homeFeedEmptyMessage => 'No listings available yet.';

  @override
  String get homeFeedCategoryEmptyMessage =>
      'No listings in this category yet.';

  @override
  String get homePromoOneTitle => 'One Post,\nEvery Channel';

  @override
  String get homePromoOneSubtitle => 'Instagram, Telegram and YouTube';

  @override
  String get homePromoTwoTitle => 'New in\nYashnobod';

  @override
  String get homePromoTwoSubtitle => '4-room new builds from \$95,000';

  @override
  String get homeTopAgentsSectionTitle => 'Top Agents';

  @override
  String get homeTopAgentsExploreLinkLabel => 'Explore';

  @override
  String get homeTopAgentsRetryMessage => 'Couldn\'t load agents';

  @override
  String homeAgentAdsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ads',
      one: '$count ad',
    );
    return '$_temp0';
  }

  @override
  String homeAgentRatingCaption(String rating, int count) {
    return '★ $rating ($count)';
  }

  @override
  String get homeTopDistrictsSectionTitle => 'Top Districts';

  @override
  String get homeTopDistrictsExploreLinkLabel => 'Explore';

  @override
  String homeDistrictListingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '$count listing',
    );
    return '$_temp0';
  }

  @override
  String homeDistrictTapSemanticsLabel(String district) {
    return 'Show listings in $district';
  }

  @override
  String get searchScreenTitle => 'Search';

  @override
  String get searchInputHint => 'Search city, district, or title';

  @override
  String get searchCancelButtonLabel => 'Cancel';

  @override
  String get searchFiltersButtonLabel => 'Filters';

  @override
  String get searchSortHighestPriceLabel => 'Highest price';

  @override
  String get searchSortLowestPriceLabel => 'Lowest price';

  @override
  String get searchSortNewestLabel => 'Newest';

  @override
  String get searchResultsRetryMessage => 'Couldn\'t load listings.';

  @override
  String get searchResultsEmptyMessage => 'No listings match your search.';

  @override
  String get searchResultsFilteredEmptyMessage =>
      'No listings match your filters.';

  @override
  String get searchRecentSearchesSectionTitle => 'Recent Searches';

  @override
  String get searchRecentSearchesClearLabel => 'Clear';

  @override
  String get filterSheetTitle => 'Filters';

  @override
  String get filterSheetCloseLabel => 'Close';

  @override
  String get filterCountErrorMessage =>
      'Couldn\'t calculate matching listings.';

  @override
  String get filterApplyButtonLabel => 'Apply Filters';

  @override
  String filterApplyButtonWithCountLabel(int count) {
    return 'Apply Filters ($count)';
  }

  @override
  String get filterResetButtonLabel => 'Reset';

  @override
  String get filterAreaMinFieldLabel => 'Min. total area';

  @override
  String get filterAreaMaxFieldLabel => 'Max total area';

  @override
  String get filterCategoryFieldLabel => 'Category';

  @override
  String get filterTypeFieldLabel => 'Type';

  @override
  String get filterCategoryRentOptionLabel => 'Rent';

  @override
  String get filterCategorySaleOptionLabel => 'Sale';

  @override
  String get filterTypeResidentialOptionLabel => 'Residential';

  @override
  String get filterTypeNonresidentialOptionLabel => 'Nonresidential';

  @override
  String get filterCityFieldLabel => 'City';

  @override
  String get filterCityPickerTitle => 'City';

  @override
  String get filterCityAnyOptionLabel => 'Any city';

  @override
  String get filterDistrictFieldLabel => 'District';

  @override
  String get filterDistrictPickerTitle => 'District';

  @override
  String get filterDistrictAnyOptionLabel => 'Any district';

  @override
  String get filterDistrictPickCityFirstPlaceholder => 'Pick a city first';

  @override
  String get filterRegionsLoadingPlaceholder => 'Loading…';

  @override
  String get filterRegionsErrorPlaceholder => 'Couldn\'t load';

  @override
  String get filterFurnitureFieldLabel => 'Furniture';

  @override
  String get filterRepairFieldLabel => 'Repair';

  @override
  String get filterFurnitureWithOptionLabel => 'With furniture';

  @override
  String get filterFurnitureWithoutOptionLabel => 'Without Furniture';

  @override
  String get filterRepairNotRepairedOptionLabel => 'Not repaired';

  @override
  String get filterRepairNormalOptionLabel => 'Normal';

  @override
  String get filterRepairGoodOptionLabel => 'Good';

  @override
  String get filterRepairExcellentOptionLabel => 'Excellent';

  @override
  String get filterPriceMinFieldLabel => 'Min price';

  @override
  String get filterPriceMaxFieldLabel => 'Max price';

  @override
  String get filterRoomsFieldLabel => 'Rooms';

  @override
  String get filterSortFieldLabel => 'Sort';

  @override
  String get filterStatusFieldLabel => 'Status';

  @override
  String get filterSortNewestOptionLabel => 'Newest';

  @override
  String get filterSortHighestPriceOptionLabel => 'Highest price';

  @override
  String get filterSortLowestPriceOptionLabel => 'Lowest price';

  @override
  String get filterStatusActiveOptionLabel => 'Active';

  @override
  String get filterStatusSoldOptionLabel => 'Sold';

  @override
  String get filterStatusDraftOptionLabel => 'Draft';

  @override
  String get filterStoreyFieldLabel => 'Storey';

  @override
  String get listingOverviewSectionTitle => 'Overview';

  @override
  String get listingDescriptionSectionTitle => 'Description';

  @override
  String get listingAdditionalInfoSectionTitle => 'Additional Information';

  @override
  String get listingSizesSectionTitle => 'Sizes';

  @override
  String get listingNearbyPlacesSectionTitle => 'Nearby Places';

  @override
  String get listingLocationSectionTitle => 'Location';

  @override
  String get listingNotFoundMessage =>
      'This listing is no longer available.\nIt may have been sold or removed.';

  @override
  String get listingLoadErrorMessage => 'Couldn\'t load this listing.';

  @override
  String get listingAgentUnavailableLabel => 'Agent details unavailable';

  @override
  String listingAgentStatsLine(int adsCount, int dealsClosedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      adsCount,
      locale: localeName,
      other: 'Agent · $adsCount listings · $dealsClosedCount closed',
      one: 'Agent · $adsCount listing · $dealsClosedCount closed',
    );
    return '$_temp0';
  }

  @override
  String listingAgentCallSemanticsLabel(String fullName) {
    return 'Call $fullName';
  }

  @override
  String get listingSubmitApplicationButtonLabel => 'Submit an application';

  @override
  String get listingFavouriteUpdateErrorMessage =>
      'Couldn\'t update favourites';

  @override
  String get listingSaveThePlaceButtonLabel => 'Save the Place';

  @override
  String get listingSavedButtonLabel => 'Saved';

  @override
  String get listingNavBackSemanticsLabel => 'Back';

  @override
  String get listingNavShareSemanticsLabel => 'Share';

  @override
  String get listingHeroVideoBadgeLabel => 'Video';

  @override
  String get listingLinkCopiedToastMessage => 'Link copied for sharing';

  @override
  String get listingNoLocationMessage =>
      'No location provided for this listing.';

  @override
  String get listingAskingPriceLabel => 'Asking price';

  @override
  String get listingSizesAreaLabel => 'Area';

  @override
  String get listingSizesRoomsLabel => 'Rooms';

  @override
  String get listingSizesFloorLabel => 'Floor';

  @override
  String get listingSizesTypeLabel => 'Type';

  @override
  String get listingTourSectionTitle => '3D Tour';

  @override
  String get listingTourViewSemanticsLabel => 'View 3D Tour';

  @override
  String get listingTourBannerLabel => 'Live 3D Tour';

  @override
  String get listingTourInvalidLinkMessage =>
      'This listing\'s 3D tour link isn\'t valid.';

  @override
  String get listingTourLoadErrorMessage => 'Couldn\'t load the 3D tour.';

  @override
  String get listingTypeResidentialLabel => 'Residential';

  @override
  String get listingTypeNonresidentialLabel => 'Nonresidential';

  @override
  String get listingCategorySaleLabel => 'Sale';

  @override
  String get listingCategoryRentLabel => 'Rent';

  @override
  String get listingRepairmentNotRepairedLabel => 'Not repaired';

  @override
  String get listingRepairmentNormalLabel => 'Normal';

  @override
  String get listingRepairmentGoodLabel => 'Good';

  @override
  String get listingRepairmentExcellentLabel => 'Excellent';

  @override
  String get listingFurnitureWithLabel => 'With furniture';

  @override
  String get listingFurnitureWithoutLabel => 'Without Furniture';

  @override
  String listingRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '$count room',
    );
    return '$_temp0';
  }

  @override
  String get galleryEmptyStateMessage =>
      'No photos available for this listing.';

  @override
  String get galleryVideoUnsupportedMessage =>
      'Video preview isn\'t available in the gallery yet.';

  @override
  String get galleryUnsupportedMediaMessage =>
      'This media type can\'t be previewed.';

  @override
  String get galleryOpenVideoExternallyLabel => 'Open video';

  @override
  String get galleryVideoLinkCopiedToastMessage =>
      'Couldn\'t open the video — link copied instead. Paste it into your browser to watch.';

  @override
  String galleryPositionSemanticsLabel(int current, int total) {
    return 'Gallery position $current of $total';
  }

  @override
  String galleryThumbnailSemanticsLabel(int index, int total) {
    return 'Photo $index of $total';
  }

  @override
  String get galleryCloseTooltip => 'Close gallery';

  @override
  String galleryCounterSemanticsLabel(String label) {
    return 'Photo $label';
  }

  @override
  String get mapNavBackSemanticsLabel => 'Back';

  @override
  String get mapTitleLabel => 'Map';

  @override
  String get mapShowListSemanticsLabel => 'Show list';

  @override
  String mapPinnedPartialCountLabel(int pinned, int total) {
    return '$pinned of $total on the map';
  }

  @override
  String mapPartialResultsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Showing the first $count matches',
      one: 'Showing the first $count match',
    );
    return '$_temp0';
  }

  @override
  String get mapUpdatingResultsLabel => 'Updating…';

  @override
  String get mapFiltersButtonLabel => 'Filters';

  @override
  String get mapNoLocationResultsMessage =>
      'None of these listings have a saved location.';

  @override
  String get mapNoResultsMessage => 'No listings match your search.';

  @override
  String mapClusterSemanticsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings here, tap to zoom in',
      one: '$count listing here, tap to zoom in',
    );
    return '$_temp0';
  }

  @override
  String mapPinSemanticsLabel(String title, String price) {
    return '$title, $price';
  }

  @override
  String get savedListingsNavBackSemanticsLabel => 'Back';

  @override
  String get savedListingsScreenTitle => 'Saved Listings';

  @override
  String get savedListingsSignInPromptMessage =>
      'Sign in to see your saved listings.';

  @override
  String get savedListingsSignInButtonLabel => 'Sign In';

  @override
  String get savedListingsLoadErrorMessage =>
      'Couldn\'t load your saved listings';

  @override
  String get savedListingsEmptyStateMessage =>
      'You haven\'t saved any listings yet.';

  @override
  String get sharedConfirmDialogCancelLabel => 'Cancel';

  @override
  String sharedDeleteConfirmTitle(String subject) {
    return 'Delete $subject?';
  }

  @override
  String get sharedDeleteConfirmBody => 'This action cannot be undone.';

  @override
  String get sharedDeleteConfirmDeleteLabel => 'Delete';

  @override
  String get sharedDiscardChangesTitle => 'Discard changes?';

  @override
  String get sharedDiscardChangesBody =>
      'You have unsaved changes. If you leave now, they won\'t be saved.';

  @override
  String get sharedDiscardChangesDiscardLabel => 'Discard';

  @override
  String get sharedSignOutTitle => 'Log out?';

  @override
  String get sharedSignOutBody =>
      'You\'ll need to sign in again to access your account.';

  @override
  String get sharedSignOutConfirmLabel => 'Logout';

  @override
  String get sharedNoReviewsYetLabel => 'No reviews yet';

  @override
  String sharedRatingLabel(String rating) {
    return 'Review: $rating/5';
  }

  @override
  String get sharedStatusUnknownLabel => 'Unknown';

  @override
  String get sharedAdStageActiveLabel => 'Active';

  @override
  String get sharedAdStageSoldLabel => 'Sold';

  @override
  String get sharedAdStageDraftLabel => 'Draft';

  @override
  String get sharedLeadStatusNewLabel => 'New';

  @override
  String get sharedLeadStatusCouldNotConnectLabel => 'Could Not Connect';

  @override
  String get sharedLeadStatusNeedToCallBackLabel => 'Need To Call Back';

  @override
  String get sharedLeadStatusRejectedLabel => 'Rejected';

  @override
  String get sharedLeadStatusAcceptedLabel => 'Accepted';

  @override
  String get sharedPublishStatusPendingLabel => 'PENDING';

  @override
  String get sharedPublishStatusAwaitingReviewLabel =>
      'DRAFTED_AWAITING_REVIEW';

  @override
  String get sharedPublishStatusPublishedLabel => 'PUBLISHED';

  @override
  String get sharedPublishStatusFailedLabel => 'FAILED';

  @override
  String get sharedGenericErrorMessage => 'Something went wrong.';

  @override
  String get sharedOfflineErrorMessage =>
      'No connection. Check your network and try again.';

  @override
  String get sharedShowPasswordLabel => 'Show password';

  @override
  String get sharedHidePasswordLabel => 'Hide password';

  @override
  String get sharedChangePhotoLabel => 'Change photo';

  @override
  String get sharedMediaSourceCloseLabel => 'Close';

  @override
  String get sharedMediaSourceCameraLabel => 'Camera';

  @override
  String get sharedMediaSourceGalleryLabel => 'Choose from library';

  @override
  String get sharedNavRowBackLabel => 'Back';

  @override
  String get sharedNavRowCloseLabel => 'Close';

  @override
  String sharedDialFallbackToastMessage(String phone) {
    return 'Couldn\'t open the dialer — phone number copied: $phone';
  }

  @override
  String get sharedFavouriteUpdateFailedMessage =>
      'Couldn\'t update favourites';

  @override
  String get sharedFavouriteAddSemanticsLabel => 'Add to favourites';

  @override
  String get sharedFavouriteRemoveSemanticsLabel => 'Remove from favourites';

  @override
  String get sharedSignInToSaveMessage => 'Sign in to save listings';

  @override
  String get sharedSignInActionLabel => 'Sign in';

  @override
  String get sharedClearFiltersActionLabel => 'Clear filters';

  @override
  String get sharedLoadMoreFailedLabel => 'Couldn\'t load more — Retry';

  @override
  String get sharedLoadMoreLabel => 'Load more';

  @override
  String get sharedRetryLabel => 'Retry';

  @override
  String get sharedListingCardSaleBadgeLabel => 'Sale';

  @override
  String get sharedListingCardRentBadgeLabel => 'Rent';

  @override
  String sharedRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '$count room',
    );
    return '$_temp0';
  }

  @override
  String get sharedPricePerMonthSuffix => '/month';

  @override
  String get navTabHomeLabel => 'Home';

  @override
  String get navTabSearchLabel => 'Search';

  @override
  String get navTabWorkLabel => 'Work';

  @override
  String get navTabDashboardLabel => 'Statistics';

  @override
  String get navTabMyAdsLabel => 'My Ads';

  @override
  String get navTabLeadsLabel => 'Leads';

  @override
  String get navTabCoworkersLabel => 'Coworkers';

  @override
  String get navTabAgentsLabel => 'Agents';

  @override
  String get navTabProfileLabel => 'Profile';

  @override
  String get permissionsHeaderTitle => 'Allow La Casa to…';

  @override
  String get permissionsCameraRowTitle => 'Camera & Photos';

  @override
  String get permissionsCameraRowBody =>
      'To add photos to your listings and profile avatar';

  @override
  String get permissionsNotificationsRowTitle => 'Notifications';

  @override
  String get permissionsNotificationsRowBody =>
      'To alert you about new leads and publish status.';

  @override
  String get permissionsNotNowButtonLabel => 'Not now';

  @override
  String get permissionsContinueButtonLabel => 'Continue';

  @override
  String get permissionsAllowButtonLabel => 'Allow';

  @override
  String get permissionsAllowedStatusLabel => 'Allowed';

  @override
  String get permissionsLimitedStatusLabel =>
      'Allowed — limited to selected photos. Tap to choose more.';

  @override
  String get permissionsDeniedStatusLabel =>
      'Not allowed — you can change this in system settings';

  @override
  String get permissionsPermanentlyDeniedStatusLabel =>
      'Not allowed — tap to open system settings';

  @override
  String get permissionsUnavailableStatusLabel =>
      'Not available in this build yet';

  @override
  String get onboardingSkipButtonLabel => 'Skip';

  @override
  String get onboardingNextButtonLabel => 'Next';

  @override
  String get onboardingGetStartedButtonLabel => 'Get Started';

  @override
  String get onboardingSlideOneTitle => 'Manage every listing in one place';

  @override
  String get onboardingSlideOneBody =>
      'Keep all your listings organized and easy to access, all in one app.';

  @override
  String get onboardingSlideTwoTitle => 'Share to every channel at once';

  @override
  String get onboardingSlideTwoBody =>
      'Publish to Instagram, Telegram and more without leaving the app.';

  @override
  String get onboardingSlideThreeTitle =>
      'Track leads from first contact to close';

  @override
  String get onboardingSlideThreeBody =>
      'Sort and follow up on every inquiry so nothing slips through.';

  @override
  String get listingEditorCreateNavTitle => 'Add New Post';

  @override
  String get listingEditorEditNavTitle => 'Update New Post';

  @override
  String get listingEditorPublishStatusNavTitle => 'Publish Status';

  @override
  String get listingEditorWizardBackLabel => 'Back';

  @override
  String get listingEditorWizardNextLabel => 'Next';

  @override
  String get listingEditorWizardCreateLabel => 'Create';

  @override
  String get listingEditorWizardDisabledReasonMessage =>
      'Fill in the required fields to continue.';

  @override
  String get listingEditorStepBasicsLabel => 'Basics';

  @override
  String get listingEditorStepDetailsLabel => 'Details';

  @override
  String get listingEditorStepPhotosLabel => 'Photos';

  @override
  String get listingEditorStepPublishLabel => 'Publish';

  @override
  String listingEditorStepGoToSemanticsLabel(String step) {
    return 'Go to $step';
  }

  @override
  String get listingEditorCreatePublishNoticeMessage =>
      'Publishing is available once this listing is created — tap Create, then use the per-channel buttons on the listing\'s own edit screen.';

  @override
  String get listingEditorSummaryCardTitle => 'Summary';

  @override
  String listingEditorSummaryPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '$count photo',
    );
    return '$_temp0';
  }

  @override
  String get listingEditorSummaryNotSetLabel => 'Not set';

  @override
  String get listingEditorPendingUploadsMessage =>
      'Please wait for photos/video to finish uploading.';

  @override
  String get listingEditorFailedUploadsMessage =>
      'Some photos/video didn\'t upload. Remove them and add them again before saving.';

  @override
  String get listingEditorCreatePendingLabel => 'Creating';

  @override
  String get listingEditorCreateSuccessMessage => 'Successfully created';

  @override
  String get listingEditorUpdatePendingLabel => 'Updating';

  @override
  String get listingEditorUpdateSuccessMessage => 'Successfully updated';

  @override
  String get listingEditorDeletePendingLabel => 'Deleting';

  @override
  String get listingEditorDeleteSuccessMessage => 'Listing deleted';

  @override
  String get listingEditorGenericErrorMessage => 'Something went wrong.';

  @override
  String get listingEditorNetworkErrorMessage =>
      'No connection. Check your network and try again.';

  @override
  String get listingEditorLoadErrorMessage => 'Couldn\'t load this listing.';

  @override
  String get listingEditorDeleteConfirmSubject => 'listing';

  @override
  String get listingEditorTitleFieldLabel => 'Title';

  @override
  String get listingEditorCityFieldLabel => 'City';

  @override
  String get listingEditorDistrictFieldLabel => 'District';

  @override
  String get listingEditorDistrictDisabledHint => 'Pick a city first';

  @override
  String get listingEditorAddressFieldLabel => 'Address';

  @override
  String get listingEditorReferenceFieldLabel => 'Reference';

  @override
  String get listingEditorReferenceHint => 'Orientation / landmark';

  @override
  String get listingEditorTypeFieldLabel => 'Type';

  @override
  String get listingEditorCategoryFieldLabel => 'Category';

  @override
  String get listingEditorRepairFieldLabel => 'Repair';

  @override
  String get listingEditorFurnitureFieldLabel => 'Furniture';

  @override
  String get listingEditorPriceTypeFieldLabel => 'Price type';

  @override
  String get listingEditorStatusFieldLabel => 'Status';

  @override
  String get listingEditorRoomsFieldLabel => 'Rooms';

  @override
  String get listingEditorAreaFieldLabel => 'Area';

  @override
  String get listingEditorAreaUnitSuffix => 'm²';

  @override
  String get listingEditorStoreyFieldLabel => 'Storey';

  @override
  String get listingEditorFloorsFieldLabel => 'Floors';

  @override
  String get listingEditorHashtagsFieldLabel => 'Hashtags';

  @override
  String get listingEditorHashtagsHint => '#new #2024';

  @override
  String get listingEditorPriceFieldLabel => 'Price';

  @override
  String get listingEditorDescriptionFieldLabel => 'Description';

  @override
  String get listingEditorTypeResidentialOption => 'Residential';

  @override
  String get listingEditorTypeNonresidentialOption => 'Nonresidential';

  @override
  String get listingEditorCategoryRentOption => 'Rent';

  @override
  String get listingEditorCategorySaleOption => 'Sale';

  @override
  String get listingEditorRepairNotRepairedOption => 'Not repaired';

  @override
  String get listingEditorRepairNormalOption => 'Normal';

  @override
  String get listingEditorRepairGoodOption => 'Good';

  @override
  String get listingEditorRepairExcellentOption => 'Excellent';

  @override
  String get listingEditorFurnitureWithOption => 'With furniture';

  @override
  String get listingEditorFurnitureWithoutOption => 'Without Furniture';

  @override
  String get listingEditorPriceTypeUzsOption => 'so\'m';

  @override
  String get listingEditorPriceTypeUsdOption => 'y.e';

  @override
  String get listingEditorStageActiveOption => 'Active';

  @override
  String get listingEditorStageSoldOption => 'Sold';

  @override
  String get listingEditorStageDraftOption => 'Draft';

  @override
  String get listingEditorPricePreviewPlaceholder =>
      'Enter a price to see a preview.';

  @override
  String listingEditorPricePreviewText(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get listingEditorNearbyPlacesLabel => 'Nearby Places';

  @override
  String get listingEditorNearbyPlacesHint =>
      'e.g. Chilonzor metro station (7 min walk)';

  @override
  String get listingEditorNearbyPlacesAddButtonLabel => 'Add';

  @override
  String get listingEditorAdditionalInfoLabel => 'Additional Info';

  @override
  String get listingEditorAdditionalInfoAddButtonLabel => 'Add';

  @override
  String get listingEditorAdditionalInfoKeyHint => 'Key';

  @override
  String get listingEditorAdditionalInfoValueHint => 'Value';

  @override
  String get listingEditorNoExistingPhotosMessage =>
      'No photos on this listing yet.';

  @override
  String get listingEditorExistingPhotosLabel => 'Existing Photos';

  @override
  String get listingEditorAddPhotosLabel => 'Add Photos';

  @override
  String get listingEditorAddPhotosButtonLabel => 'Add photos';

  @override
  String get listingEditorAddVideoButtonLabel => 'Add video';

  @override
  String get listingEditorAddVideoOptionalHint => 'Optional · up to 70 MB';

  @override
  String get listingEditorMediaLimitsHint =>
      'Up to 5 images (5MB each). An optional single video up to 70MB.';

  @override
  String get listingEditorAddPhotoSheetTitle => 'Add photo';

  @override
  String get listingEditorAddVideoSheetTitle => 'Add video';

  @override
  String get listingEditorVideoFallbackFileName => 'Video';

  @override
  String get listingEditorUploadFailedFallbackMessage =>
      'Couldn\'t upload. Please try again.';

  @override
  String get listingEditorUploadedStatusLabel => 'Uploaded';

  @override
  String listingEditorUploadingProgressLabel(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get listingEditorRetryUploadLabel => 'Retry upload';

  @override
  String get listingEditorPublishSectionLabel => 'Publish';

  @override
  String get listingEditorChannelInstagramLabel => 'Instagram';

  @override
  String get listingEditorChannelTelegramLabel => 'Telegram';

  @override
  String get listingEditorChannelYoutubeLabel => 'YouTube';

  @override
  String get listingEditorChannelOlxLabel => 'OLX';

  @override
  String get listingEditorChannelThreadsLabel => 'Threads';

  @override
  String get listingEditorChannelFacebookMarketplaceLabel =>
      'Facebook Marketplace';

  @override
  String get listingEditorChannelXLabel => 'X';

  @override
  String get listingEditorChannelLinkedinLabel => 'LinkedIn';

  @override
  String get listingEditorChannelUnknownLabel => 'Unknown channel';

  @override
  String get listingEditorYoutubeUnavailableHint =>
      'Beta — not available in this build.';

  @override
  String get listingEditorOlxUnavailableHint =>
      'OLX cross-posting is only available from the desktop app (requires a browser extension).';

  @override
  String get listingEditorThreadsUnavailableHint =>
      'Threads posting needs a Threads profile linked to an Instagram professional account — this build never requests that permission.';

  @override
  String get listingEditorFacebookMarketplaceUnavailableHint =>
      'Facebook Marketplace has no compliant automation path on any platform — its listings have to be posted by hand.';

  @override
  String get listingEditorXUnavailableHint =>
      'X posting needs its own X API app on a paid write tier — neither is set up in this build.';

  @override
  String get listingEditorLinkedinUnavailableHint =>
      'LinkedIn posting needs an approved LinkedIn Marketing API app — this build has no LinkedIn credentials.';

  @override
  String get listingEditorPublishStatusLinkLabel => 'Publish Status';

  @override
  String get listingEditorPublishChannelsSheetTitle =>
      'Select the channels you want to publish to!';

  @override
  String get listingEditorInstagramLoadErrorMessage =>
      'Couldn\'t load connected Instagram accounts.';

  @override
  String listingEditorInstagramFollowersSubtitle(String count) {
    return 'Instagram · $count followers';
  }

  @override
  String get listingEditorNoInstagramAccountMessage =>
      'No Instagram account is connected. You can connect one in Settings, or draft the post yourself.';

  @override
  String get listingEditorNoTelegramChannelMessage =>
      'No Telegram channel is connected.';

  @override
  String listingEditorTelegramChannelRowLabel(int chatId) {
    return 'Telegram channel #$chatId';
  }

  @override
  String get listingEditorCancelButtonLabel => 'Cancel';

  @override
  String get listingEditorPublishButtonLabel => 'Publish';

  @override
  String listingEditorInstagramPublishFailedMessage(String usernames) {
    return 'Instagram publish failed for $usernames';
  }

  @override
  String get listingEditorInstagramPublishSuccessMessage =>
      'Instagram post published!';

  @override
  String listingEditorTelegramPublishFailedMessage(String chatIds) {
    return 'Telegram publish failed for $chatIds';
  }

  @override
  String get listingEditorTelegramPublishSuccessMessage =>
      'Telegram post published!';

  @override
  String get listingEditorPublishStatusLoadErrorMessage =>
      'Couldn\'t load publish status.';

  @override
  String get listingEditorOlxNotAvailableLabel => 'Not available on mobile';

  @override
  String listingEditorLastAttemptLabel(String date) {
    return 'Last attempt: $date';
  }

  @override
  String get listingEditorViewPostLinkLabel => 'View Post';

  @override
  String get listingEditorPostLinkCopiedMessage =>
      'Post link copied to clipboard.';

  @override
  String get listingEditorYoutubeNonRetryableReason =>
      'YouTube has no server-side publish call to retry — the browser performs the upload itself under your own Google session. Upload again and report the result.';

  @override
  String get listingEditorOlxNonRetryableReason =>
      'OLX posting happens through the browser extension with a human reviewing and clicking Publish. Retry the cross-post from the extension instead.';

  @override
  String get listingEditorUnknownChannelReason => 'Unknown publish channel.';

  @override
  String listingEditorRetrySuccessMessage(String channel) {
    return '$channel publish retried successfully.';
  }

  @override
  String get listingEditorSaveButtonLabel => 'Save';

  @override
  String get listingEditorDeleteButtonLabel => 'Delete';

  @override
  String get listingEditorTitleRequiredError => 'Title is required';

  @override
  String get listingEditorCityRequiredError => 'City is required';

  @override
  String get listingEditorDistrictRequiredError => 'District is required';

  @override
  String get listingEditorAddressRequiredError => 'Address is required';

  @override
  String get listingEditorReferenceRequiredError => 'Reference is required';

  @override
  String get listingEditorDescriptionRequiredError => 'Description is required';

  @override
  String get myListingsNavTitle => 'My Ads';

  @override
  String get myListingsFilterButtonLabel => 'Filter';

  @override
  String get myListingsCreateButtonSemanticsLabel => 'Create New Post';

  @override
  String get myListingsLoadErrorMessage => 'Couldn\'t load your ads.';

  @override
  String get myListingsEmptyStateMessage => 'Ads not found.';

  @override
  String get myListingsFilteredEmptyStateMessage =>
      'No ads match your filters.';

  @override
  String get myListingsEmptyStateActionLabel => 'Create New Post';

  @override
  String get myListingsEditButtonSemanticsLabel => 'Edit';

  @override
  String get myListingsStageAllLabel => 'All';

  @override
  String myListingsStageCountActiveLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active',
      one: '$count active',
    );
    return '$_temp0';
  }

  @override
  String myListingsStageCountSoldLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sold',
      one: '$count sold',
    );
    return '$_temp0';
  }

  @override
  String myListingsStageCountDraftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts',
      one: '$count draft',
    );
    return '$_temp0';
  }

  @override
  String myListingsStageFilterSemanticsLabel(String stage) {
    return 'Show $stage ads';
  }

  @override
  String get myListingsChannelPublishedLabel => 'Published';

  @override
  String get myListingsChannelFailedLabel => 'Failed';

  @override
  String get myListingsChannelPendingLabel => 'Publishing…';

  @override
  String get myListingsChannelNotPublishedLabel => 'Not published';

  @override
  String myListingsChannelBadgeSemanticsLabel(String channel, String status) {
    return '$channel — $status';
  }

  @override
  String get agentsDirectoryScreenTitle => 'Agents';

  @override
  String get agentsDirectoryLoadErrorMessage => 'Couldn\'t load agents';

  @override
  String get agentsDirectoryEmptyMessage => 'No agents found.';

  @override
  String agentsCardAdsCountLabel(int count) {
    return 'Ads: $count';
  }

  @override
  String get agentsProfileNavBackLabel => 'Back';

  @override
  String get agentsProfileScreenTitle => 'Agent Information';

  @override
  String get agentsProfileLoadErrorMessage => 'Couldn\'t load this agent';

  @override
  String get agentsProfileNotFoundMessage =>
      'This agent is no longer available.';

  @override
  String get agentsProfileGoBackLabel => 'Go back';

  @override
  String get agentsInfoFullNameLabel => 'Full name:';

  @override
  String get agentsInfoEmailLabel => 'E-mail:';

  @override
  String get agentsInfoPhoneLabel => 'Phone:';

  @override
  String get agentsInfoAddressLabel => 'Address:';

  @override
  String get agentsInfoRatingLabel => 'Rating:';

  @override
  String get agentsInfoCallButtonLabel => 'Call';

  @override
  String get agentsInfoMessageButtonLabel => 'Message';

  @override
  String get agentsAdsGridLoadErrorMessage =>
      'Couldn\'t load this agent\'s listings';

  @override
  String get agentsAdsGridEmptyMessage => 'No listings found.';

  @override
  String get agentsAdsGridHeading => 'Ads List';

  @override
  String get reviewsRatingRequiredError => 'Please choose a rating.';

  @override
  String get reviewsUpdateSuccessToast => 'Review updated.';

  @override
  String get reviewsPostSuccessToast => 'Review posted.';

  @override
  String get reviewsDeleteSuccessToast => 'Review deleted.';

  @override
  String get reviewsSelfReviewForbiddenError => 'You can\'t review yourself.';

  @override
  String get reviewsAgentNotFoundError => 'This agent is no longer available.';

  @override
  String get reviewsSaveGenericErrorMessage =>
      'Couldn\'t save your review right now. Please try again.';

  @override
  String get reviewsNetworkErrorMessage =>
      'No connection. Check your network and try again.';

  @override
  String get reviewsSheetEditTitle => 'Edit Your Review';

  @override
  String get reviewsSheetLeaveTitle => 'Leave a Review';

  @override
  String get reviewsSheetCloseLabel => 'Close';

  @override
  String reviewsSheetPromptMessage(String agentName) {
    return 'Share your experience working with $agentName.';
  }

  @override
  String get reviewsSheetCommentLabel => 'COMMENT (OPTIONAL)';

  @override
  String get reviewsSheetCommentHint =>
      'What was it like working with this agent?';

  @override
  String get reviewsSheetUpdateButtonLabel => 'Update review';

  @override
  String get reviewsSheetPostButtonLabel => 'Post review';

  @override
  String get reviewsSheetDeletingLabel => 'Deleting…';

  @override
  String get reviewsSheetDeleteButtonLabel => 'Delete review';

  @override
  String reviewsSectionHeading(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get reviewsSectionLoadErrorMessage =>
      'Couldn\'t load this agent\'s reviews';

  @override
  String get reviewsSectionEmptyMessage => 'No reviews yet.';

  @override
  String get reviewsSectionSignInPromptMessage => 'Sign in to leave a review.';

  @override
  String get reviewsSectionSignInButtonLabel => 'Sign In';

  @override
  String get reviewsSectionSelfProfileMessage =>
      'You can\'t review your own profile.';

  @override
  String get reviewsSectionLeaveButtonLabel => 'Leave a review';

  @override
  String get reviewsSectionEditButtonLabel => 'Edit your review';

  @override
  String get reviewsSectionLoadMoreLabel => 'Show more reviews';

  @override
  String get profileAgentScreenTitle => 'Profile';

  @override
  String get profileAgentAccountGroupLabel => 'Account';

  @override
  String get profileAgentEditProfileRowTitle => 'Edit Profile';

  @override
  String get profileAgentConnectedAccountsRowTitle => 'Connected Accounts';

  @override
  String get profileAgentSettingsRowTitle => 'Settings';

  @override
  String get profileAgentMessagesRowTitle => 'Messages';

  @override
  String get profileAgentLanguageRowTitle => 'Language';

  @override
  String get profileAgentWorkspaceGroupLabel => 'Workspace';

  @override
  String get profileAgentBrowseModeRowTitle => 'Browse listings';

  @override
  String get profileAgentBrowseModeRowSubtitle =>
      'Search and view ads like a client';

  @override
  String get profileAgentWorkModeRowTitle => 'Go to workspace';

  @override
  String get profileAgentWorkModeRowSubtitle =>
      'Statistics, ads, leads and coworkers';

  @override
  String get profileAgentSessionGroupLabel => 'Session';

  @override
  String get profileAgentLogoutRowTitle => 'Logout';

  @override
  String get profileBuyerScreenTitle => 'Profile';

  @override
  String get profileBuyerAccountGroupLabel => 'Account';

  @override
  String get profileBuyerSavedListingsRowTitle => 'Saved Listings';

  @override
  String profileBuyerSavedListingsRowSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '$count listing',
      zero: 'No listings',
    );
    return '$_temp0';
  }

  @override
  String get profileBuyerUpdateProfileRowTitle => 'Update Profile';

  @override
  String get profileBuyerLanguageRowTitle => 'Language';

  @override
  String get profileBuyerRegisterAsAgentRowTitle => 'Register as Agent';

  @override
  String get profileBuyerRealtorPendingRowTitle =>
      'Realtor application under review';

  @override
  String profileBuyerRealtorPendingRowSubtitle(String phone) {
    return 'We\'ll call $phone — usually within one business day.';
  }

  @override
  String get profileBuyerRealtorPendingNoPhoneSubtitle =>
      'We\'ll call you — usually within one business day.';

  @override
  String get profileBuyerRealtorRejectedRowTitle =>
      'Realtor application not approved';

  @override
  String get profileBuyerRealtorRejectedRowSubtitle =>
      'Contact us and we\'ll go through it with you.';

  @override
  String get profileBuyerRealtorRejectedActionLabel => 'Contact Us';

  @override
  String profileBuyerRealtorAppliedAtLabel(String date) {
    return 'Applied $date';
  }

  @override
  String get profileBuyerSessionGroupLabel => 'Session';

  @override
  String get profileBuyerLogoutRowTitle => 'Logout';

  @override
  String get profileBuyerRegisterLinkCopiedToast =>
      'Couldn\'t open your browser — Registration form link copied instead. Paste it into your browser to apply.';

  @override
  String get profileSignedOutScreenTitle => 'Profile';

  @override
  String get profileSignedOutPreferencesGroupLabel => 'Preferences';

  @override
  String get profileSignedOutLanguageRowTitle => 'Language';

  @override
  String get profileSignedOutContactUsRowTitle => 'Contact Us';

  @override
  String get profileSignedOutPromptMessage =>
      'Sign in to save listings, message agents, and manage your business.';

  @override
  String get profileSignedOutSignInButtonLabel => 'Sign In';

  @override
  String get profileSignedOutSignUpButtonLabel => 'Sign Up';

  @override
  String get authLoginRequiredFieldsError => 'Required fields are not filled';

  @override
  String get authLoginSuccessToast => 'User successfully logged in.';

  @override
  String get authLoginInvalidCredentialsError => 'Invalid email or password';

  @override
  String get authLoginForgotPasswordHintMessage =>
      'Forgot it? Tap Forgot password.';

  @override
  String get authLoginNetworkErrorMessage =>
      'No connection. Check your network and try again.';

  @override
  String get authLoginGenericErrorMessage => 'Something went wrong';

  @override
  String get authLoginWelcomeHeading => 'Welcome back';

  @override
  String get authLoginEmailFieldLabel => 'Email';

  @override
  String get authLoginPasswordFieldLabel => 'Password';

  @override
  String get authLoginSubmitButtonLabel => 'Sign in';

  @override
  String get authLoginForgotPasswordLinkLabel => 'Forgot password?';

  @override
  String authLoginForgotPasswordContactMessage(String email) {
    return 'I forgot the password for $email and can\'t sign in. Please help me reset it.';
  }

  @override
  String get authLoginForgotPasswordContactMessageNoEmail =>
      'I forgot my password and can\'t sign in. Please help me reset it.';

  @override
  String get authLoginFooterLinkText => 'Don\'t you have an account?';

  @override
  String get authRegisterHeading => 'Create your account';

  @override
  String get authRegisterAccountTypeLabel => 'I\'m signing up as';

  @override
  String get authRegisterBuyerCardTitle => 'Buyer';

  @override
  String get authRegisterBuyerCardSubtitle => 'Browse and save homes';

  @override
  String get authRegisterRealtorCardTitle => 'Realtor';

  @override
  String get authRegisterRealtorCardSubtitle => 'Post listings, work leads';

  @override
  String get authRegisterFullNameFieldLabel => 'Full name';

  @override
  String get authRegisterPhoneFieldLabel => 'Phone number';

  @override
  String get authRegisterEmailFieldLabel => 'Email';

  @override
  String get authRegisterPasswordFieldLabel => 'Password';

  @override
  String get authRegisterPasswordHint => 'At least 6 characters';

  @override
  String get authRegisterRealtorTypeLabel => 'Realtor type';

  @override
  String get authRegisterSoloAgentChipLabel => 'Solo agent';

  @override
  String get authRegisterAgencyChipLabel => 'Agency';

  @override
  String get authRegisterSoloAgentHint =>
      'You work under your own name. Your workspace opens on Statistics with your own listings and leads; Coworkers stays hidden until you switch to an agency.';

  @override
  String get authRegisterAgencyNameFieldLabel => 'Agency name';

  @override
  String get authRegisterAgencyNameHelperText =>
      'Shown on the team\'s listings in place of the agent\'s own name.';

  @override
  String get authRegisterOfficePhoneFieldLabel => 'Office phone';

  @override
  String get authRegisterTeamSizeLabel => 'Team size';

  @override
  String get authRegisterTeamSizeJustMeLabel => 'Just me for now';

  @override
  String get authRegisterTeamSizeTwoToFiveLabel => '2–5';

  @override
  String get authRegisterTeamSizeSixToFifteenLabel => '6–15';

  @override
  String get authRegisterTeamSizeSixteenPlusLabel => '16+';

  @override
  String get authRegisterAgencyOwnerHint =>
      'You sign up as the agency owner: invite coworkers, assign leads to them, and see the whole team\'s statistics. Coworkers see only what you assign.';

  @override
  String get authRegisterVerificationCalloutMessage =>
      'Realtor accounts are verified before the Work tab unlocks. We\'ll call the number above — usually within one business day.';

  @override
  String get authRegisterRequiredFieldsError =>
      'Required fields are not filled';

  @override
  String get authRegisterInvalidPhoneError => 'Invalid phone number format';

  @override
  String get authRegisterFullNameRequiredError => 'Full name is required';

  @override
  String get authRegisterPhoneRequiredError => 'Phone number is required';

  @override
  String get authRegisterEmailRequiredError => 'Email is required';

  @override
  String get authRegisterEmailInvalidError => 'Invalid email address format';

  @override
  String get authRegisterPasswordRequiredError => 'Password is required';

  @override
  String get authRegisterPasswordTooShortError =>
      'Password must be at least 6 characters';

  @override
  String get authRegisterAgencyNameRequiredError => 'Agency name is required';

  @override
  String get authRegisterRealtorSuccessToast =>
      'Account created. We\'ll verify your realtor profile shortly.';

  @override
  String get authRegisterBuyerSuccessToast => 'User successfully created.';

  @override
  String get authRegisterNetworkErrorMessage =>
      'No connection. Check your network and try again.';

  @override
  String get authRegisterGenericErrorMessage => 'Something went wrong';

  @override
  String get authRegisterRealtorSubmitButtonLabel => 'Create realtor account';

  @override
  String get authRegisterBuyerSubmitButtonLabel => 'Sign up';

  @override
  String get authRegisterFooterLinkText => 'Already have an account? Sign in';

  @override
  String get authVisibilityToggleShowLabel => 'Show password';

  @override
  String get authVisibilityToggleHideLabel => 'Hide password';

  @override
  String get authCloseButtonLabel => 'Close';

  @override
  String get editProfileScreenTitle => 'Edit Profile';

  @override
  String get editProfileDiscardDialogTitle => 'Discard changes?';

  @override
  String get editProfileDiscardDialogCancelButtonLabel => 'Cancel';

  @override
  String get editProfileDiscardDialogConfirmButtonLabel => 'Discard';

  @override
  String get editProfileAvatarUploadingToast =>
      'Please wait for the photo to finish uploading.';

  @override
  String get editProfileUpdateSuccessToast => 'Profile successfully updated!';

  @override
  String editProfileUpdateErrorToast(String message) {
    return 'Error updating profile: $message';
  }

  @override
  String get editProfileNetworkErrorMessage =>
      'No connection. Check your network and try again.';

  @override
  String get editProfileGenericErrorMessage => 'Something went wrong';

  @override
  String get editProfileSignedOutMessage => 'Sign in to edit your profile.';

  @override
  String get editProfileSignedOutGoBackLabel => 'Go back';

  @override
  String get editProfileFullNameFieldLabel => 'Full name';

  @override
  String get editProfileFullNameRequiredError => 'First name is required';

  @override
  String get editProfilePhoneFieldLabel => 'Phone';

  @override
  String get editProfilePhoneInvalidError => 'Invalid Uzbekistan phone number';

  @override
  String get editProfileEmailFieldLabel => 'Email';

  @override
  String get editProfileEmailRequiredError => 'Email is required';

  @override
  String get editProfilePasswordFieldLabel => 'Password';

  @override
  String get editProfilePasswordHint =>
      'Leave blank to keep your current password';

  @override
  String get editProfilePasswordLengthError =>
      'Password must be at least 6 characters';

  @override
  String get editProfileCancelButtonLabel => 'Cancel';

  @override
  String get editProfileSaveButtonLabel => 'Save';

  @override
  String get contactRequiredFieldsError => 'Required fields are not filled';

  @override
  String get contactInvalidPhoneError => 'Invalid phone number format';

  @override
  String get contactSendSuccessToast => 'Message sent successfully.';

  @override
  String get contactRateLimitedError =>
      'Too many messages just now. Please try again in a minute.';

  @override
  String get contactUnconfiguredError =>
      'The contact form isn\'t available right now. Please call the agent directly.';

  @override
  String get contactGenericErrorMessage =>
      'Couldn\'t send your message right now. Please try again.';

  @override
  String get contactNetworkErrorMessage =>
      'No connection. Check your network and try again.';

  @override
  String get contactSheetTitle => 'Contact Us';

  @override
  String get contactSheetCloseLabel => 'Close';

  @override
  String get contactSheetSubtitle =>
      'We welcome all your concerns, issues, and suggestions. Feel free to get in touch with us at your most convenient time.';

  @override
  String get contactFullNameFieldLabel => 'Full name';

  @override
  String get contactPhoneFieldLabel => 'Phone';

  @override
  String get contactMessageFieldLabel => 'Message';

  @override
  String get contactMessageFieldHintText =>
      'I\'d like to view this apartment this week.';

  @override
  String get contactSendButtonLabel => 'Send message';

  @override
  String reviewsRatingInputStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '$count star',
    );
    return '$_temp0';
  }

  @override
  String get leadsListScreenTitle => 'Leads';

  @override
  String get leadsKanbanScreenTitle => 'Kanban';

  @override
  String get leadsToggleViewKanbanLabel => 'View as Kanban';

  @override
  String get leadsToggleViewListLabel => 'View as list';

  @override
  String get leadsAddNewLeadLabel => 'Add new lead';

  @override
  String get leadsEmptyMessage => 'No leads yet.';

  @override
  String get leadsLoadErrorMessage => 'Couldn\'t load your leads.';

  @override
  String get leadsEmptyColumnMessage => 'No leads in this stage yet.';

  @override
  String get leadsCardMoveFailedMessage => 'Couldn\'t move — try again.';

  @override
  String get leadsCardMoveFailedLabel => 'Couldn\'t move';

  @override
  String leadsCardMoveRetrySemanticsLabel(String status) {
    return 'Retry moving to $status';
  }

  @override
  String get leadsCreateScreenTitle => 'Create Lead';

  @override
  String get leadsFieldFullNameLabel => 'Full name';

  @override
  String get leadsFieldPhoneLabel => 'Phone';

  @override
  String get leadsFieldEmailLabel => 'Email';

  @override
  String get leadsFieldBudgetLabel => 'Budget';

  @override
  String get leadsFieldCommitLabel => 'Commit';

  @override
  String get leadsFieldSourceLabel => 'Source';

  @override
  String get leadsCreateCommitHint => 'What are they looking for?';

  @override
  String get leadsCreateFullNameRequiredError => 'First name is required';

  @override
  String get leadsCreatePhoneRequiredError => 'Phone number is required';

  @override
  String get leadsPhoneInvalidError => 'Invalid Uzbekistan phone number';

  @override
  String get leadsDetailFullNameRequiredError => 'Full name is required';

  @override
  String get leadsBudgetInvalidError => 'Enter a valid number';

  @override
  String get leadsStatusFieldLabel => 'STATUS';

  @override
  String get leadsCallTimeLabel => 'CALL TIME';

  @override
  String get leadsSelectDateLabel => 'Select date';

  @override
  String get leadsCoworkerFieldLabel => 'COWORKER';

  @override
  String get leadsCoworkerUnavailableNote =>
      'Assigning a coworker isn\'t available in this build yet.';

  @override
  String get leadsCancelButtonLabel => 'Cancel';

  @override
  String get leadsSaveButtonLabel => 'Save';

  @override
  String get leadsCreatedToastMessage => 'Lead successfully created!';

  @override
  String leadsCreateErrorToastMessage(String message) {
    return 'Error creating lead: $message';
  }

  @override
  String get leadsUpdatedToastMessage => 'Lead successfully updated!';

  @override
  String leadsUpdateErrorToastMessage(String message) {
    return 'Error updating lead: $message';
  }

  @override
  String get leadsDeletedToastMessage => 'Lead successfully deleted!';

  @override
  String leadsDeleteErrorToastMessage(String message) {
    return 'Error deleting lead: $message';
  }

  @override
  String get leadsNoConnectionMessage =>
      'No connection. Check your network and try again.';

  @override
  String get leadsSubjectNoun => 'lead';

  @override
  String get leadsDetailCloseLabel => 'Close';

  @override
  String get leadsCallButtonLabel => 'Call';

  @override
  String leadsCallSemanticsLabel(String phone) {
    return 'Call $phone';
  }

  @override
  String get leadsDetailLoadErrorMessage => 'Couldn\'t load this lead.';

  @override
  String get leadsDeleteLeadButtonLabel => 'Delete';

  @override
  String leadsCommitMinLengthError(int min) {
    return 'At least $min characters.';
  }

  @override
  String get leadsCallbackSheetTitle => 'Enter the next call-back time';

  @override
  String get leadsConversationSheetTitle =>
      'Write briefly about the conversation';

  @override
  String get leadsConversationHint => 'At least 10 characters';

  @override
  String get leadsMoveToSheetTitle => 'Move to…';

  @override
  String get coworkersListScreenTitle => 'Coworkers';

  @override
  String get coworkersLoadErrorMessage => 'Couldn\'t load your coworkers';

  @override
  String get coworkersEmptyMessage => 'No coworkers yet.';

  @override
  String get coworkersEmptyStateActionLabel => 'Add coworker';

  @override
  String get coworkersAddNewButtonLabel => '+ Add new coworker';

  @override
  String coworkersListingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ads',
      one: '$count ad',
    );
    return '$_temp0';
  }

  @override
  String get coworkersCreateScreenTitle => 'Create coworker';

  @override
  String get coworkersUploadWaitMessage =>
      'Please wait for the photo to finish uploading.';

  @override
  String get coworkersUploadingToastLabel => 'Uploading';

  @override
  String get coworkersCreatedToastMessage => 'Coworker successfully created';

  @override
  String coworkersCreateErrorToastMessage(String message) {
    return 'Error creating coworker: $message';
  }

  @override
  String get coworkersNoConnectionMessage =>
      'No connection. Check your network and try again.';

  @override
  String get coworkersGenericErrorMessage => 'Something went wrong';

  @override
  String get coworkersSignInPromptMessage => 'Sign in to manage your team.';

  @override
  String get coworkersSignInActionLabel => 'Sign In';

  @override
  String get coworkersAgentOnlyMessage => 'Only agents can add coworkers.';

  @override
  String get coworkersGoBackLabel => 'Go back';

  @override
  String get coworkersSoloAgentMessage =>
      'Solo agents don\'t have a team. Switch to an agency account to add coworkers.';

  @override
  String get coworkersAddPhotoLabel => 'Add photo';

  @override
  String get coworkersChangePhotoLabel => 'Change photo';

  @override
  String get coworkersFieldFullNameLabel => 'Full name';

  @override
  String get coworkersFieldPhoneLabel => 'Phone';

  @override
  String get coworkersFieldEmailLabel => 'Email';

  @override
  String get coworkersFieldPasswordLabel => 'Password';

  @override
  String get coworkersPasswordHint => 'At least 6 characters';

  @override
  String get coworkersPasswordHintKeepCurrent => 'Leave blank to keep current';

  @override
  String get coworkersFullNameRequiredError => 'Full Name is required';

  @override
  String get coworkersPhoneRequiredError => 'Phone number is required';

  @override
  String get coworkersPhoneInvalidError => 'Invalid Uzbekistan phone number';

  @override
  String get coworkersEmailRequiredError => 'Email is required';

  @override
  String get coworkersPasswordRequiredError => 'Password is required';

  @override
  String get coworkersPasswordTooShortError =>
      'Password must be at least 6 characters';

  @override
  String get coworkersCancelButtonLabel => 'Cancel';

  @override
  String get coworkersSaveButtonLabel => 'Save';

  @override
  String get coworkersDeleteButtonLabel => 'Delete';

  @override
  String get coworkersSubjectNoun => 'coworker';

  @override
  String get coworkersDetailScreenTitle => 'Update coworker';

  @override
  String get coworkersNotFoundMessage =>
      'This coworker is no longer available.';

  @override
  String get coworkersDetailLoadErrorMessage => 'Couldn\'t load this coworker';

  @override
  String get coworkersUpdatedToastMessage => 'Coworker successfully updated!';

  @override
  String coworkersUpdateErrorToastMessage(String message) {
    return 'Error updating coworker: $message';
  }

  @override
  String get coworkersDeletedToastMessage => 'Coworker successfully deleted!';

  @override
  String coworkersDeleteErrorToastMessage(String message) {
    return 'Error deleting coworker: $message';
  }

  @override
  String get coworkersReadOnlyNoteMessage =>
      'Only agents can edit or delete coworkers.';

  @override
  String get coworkersActivityJustNow => 'Just now';

  @override
  String coworkersActivityMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
    );
    return '$_temp0';
  }

  @override
  String coworkersActivityHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
    );
    return '$_temp0';
  }

  @override
  String get coworkersActivityYesterday => 'Yesterday';

  @override
  String coworkersActivityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
    );
    return '$_temp0';
  }

  @override
  String get dashboardScreenHeaderTitle => 'Statistics';

  @override
  String get dashboardNotificationsSemanticsLabel => 'Notifications';

  @override
  String get dashboardCoworkerStatisticsSectionTitle => 'Coworker statistics';

  @override
  String get dashboardWorkspaceGroupLabel => 'Workspace';

  @override
  String get dashboardAdsStatisticsTitle => 'Ads statistics';

  @override
  String get dashboardAdsStatisticsLoadErrorMessage =>
      'Couldn\'t load ad statistics';

  @override
  String get dashboardNoDataForRangeMessage => 'No data for this range.';

  @override
  String get dashboardLegendCreated => 'Created';

  @override
  String get dashboardLegendSold => 'Sold';

  @override
  String dashboardChartSemanticsLabel(String range, int created, int sold) {
    return 'Ads statistics, $range: $created created, $sold sold';
  }

  @override
  String dashboardCaptionHour(String hour) {
    return 'Hour $hour';
  }

  @override
  String dashboardCaptionHoursRange(String start, String end) {
    return 'Hours $start–$end';
  }

  @override
  String dashboardCaptionDay(int day) {
    return 'Day $day';
  }

  @override
  String dashboardCaptionDaysRange(int start, int end) {
    return 'Days $start–$end';
  }

  @override
  String dashboardCaptionAllTimeChartNote(String range) {
    return '$range · chart shows this month';
  }

  @override
  String get dashboardCoworkerStatisticsLoadErrorMessage =>
      'Couldn\'t load coworker statistics';

  @override
  String get dashboardNoCoworkersMessage => 'No coworkers yet.';

  @override
  String get dashboardAddCoworkerButtonLabel => 'Add coworker';

  @override
  String get dashboardLegendAdsCount => 'Ads count';

  @override
  String get dashboardLegendLeadCount => 'Lead count';

  @override
  String get dashboardLegendSaleCount => 'Sale count';

  @override
  String dashboardCoworkerBarsSemanticsLabel(
    String name,
    int ads,
    int leads,
    int sales,
  ) {
    return '$name: $ads ads, $leads leads, $sales sales';
  }

  @override
  String get dashboardHeaderCoworkers => 'Coworkers';

  @override
  String get dashboardHeaderAds => 'Ads';

  @override
  String get dashboardHeaderLeads => 'Leads';

  @override
  String get dashboardHeaderSales => 'Sales';

  @override
  String get dashboardTileAdsCreatedLabel => 'Ads created';

  @override
  String get dashboardTileAdsSoldLabel => 'Ads sold';

  @override
  String get dashboardTileActiveLeadsLabel => 'Active leads';

  @override
  String get dashboardTileCoworkersLabel => 'Coworkers';

  @override
  String get dashboardTileTapToManageSubtitle => 'tap to manage';

  @override
  String get dashboardTileTapToViewSubtitle => 'tap to view';

  @override
  String get dashboardRangeSubtitleAll => 'all time';

  @override
  String get dashboardRangeSubtitleThisMonth => 'this month';

  @override
  String get dashboardRangeSubtitleThisWeek => 'this week';

  @override
  String get dashboardRangeSubtitleToday => 'today';

  @override
  String dashboardCallbackSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need a call back',
      one: '$count needs a call back',
    );
    return '$_temp0';
  }

  @override
  String get dashboardFilterLabelAll => 'All';

  @override
  String get dashboardFilterLabelThisMonth => 'This month';

  @override
  String get dashboardFilterLabelThisWeek => 'This week';

  @override
  String get dashboardFilterLabelToday => 'Today';

  @override
  String get dashboardWorkspaceMyAdsRowTitle => 'My Ads';

  @override
  String get dashboardWorkspaceLeadsRowTitle => 'Leads';

  @override
  String get dashboardWorkspaceCoworkersRowTitle => 'Coworkers';

  @override
  String dashboardWorkspaceMyAdsSubtitle(int listings, int drafts) {
    return '$listings listings · $drafts drafts';
  }

  @override
  String dashboardWorkspaceLeadsSubtitle(int active, int dueToday) {
    return '$active active · $dueToday need a call back';
  }

  @override
  String dashboardWorkspaceCoworkersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '$count person',
    );
    return '$_temp0';
  }

  @override
  String get notificationsScreenTitle => 'Notifications';

  @override
  String get notificationsLoadErrorMessage =>
      'Couldn\'t load your notifications.';

  @override
  String get notificationsMarkAllReadLabel => 'Mark all read';

  @override
  String get notificationsMarkedAllReadToastMessage =>
      'All notifications marked read';

  @override
  String get notificationsMarkAllReadPendingLabel => 'Marking all read';

  @override
  String get notificationsMarkAllReadErrorMessage =>
      'Couldn\'t mark your notifications read.';

  @override
  String get notificationsEmptyMessage => 'No notifications yet.';

  @override
  String get notificationsEmptyStateDetailMessage =>
      'New leads, ad approvals and publish results show up here.';

  @override
  String get notificationsEmptyStateActionLabel => 'Refresh';

  @override
  String get notificationsAgentOnlyMessage =>
      'Notifications are available to agents only.';

  @override
  String get notificationsSignInPromptMessage =>
      'Sign in to see your notifications.';

  @override
  String get notificationsGoBackLabel => 'Go back';

  @override
  String notificationsUnreadSemanticsLabel(String title) {
    return '$title, unread';
  }

  @override
  String get notificationsRelativeJustNow => 'Just now';

  @override
  String notificationsRelativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
    );
    return '$_temp0';
  }

  @override
  String notificationsRelativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
    );
    return '$_temp0';
  }

  @override
  String get notificationsRelativeYesterday => 'Yesterday';

  @override
  String notificationsRelativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
    );
    return '$_temp0';
  }

  @override
  String get messagesScreenTitle => 'Messages';

  @override
  String get messagesComingSoonTitle => 'Messaging is coming soon';

  @override
  String get messagesComingSoonBody =>
      'For now, contact leads by phone. Every lead card carries a tap-to-call number.';

  @override
  String get messagesOpenLeadsAction => 'Open Leads';

  @override
  String get connectedAccountsScreenTitle => 'Connected Accounts';

  @override
  String get connectedAccountsInstagramToggleTitle => 'Create Instagram post';

  @override
  String get connectedAccountsInstagramToggleSubtitle =>
      'Status — on when at least one account is linked';

  @override
  String get connectedAccountsTelegramToggleTitle => 'Create Telegram post';

  @override
  String get connectedAccountsTelegramToggleSubtitle =>
      'Status — on when a channel is linked';

  @override
  String get connectedAccountsYoutubeToggleTitle => 'Create Youtube post';

  @override
  String get connectedAccountsThreadsToggleTitle => 'Create Threads post';

  @override
  String get connectedAccountsFacebookMarketplaceToggleTitle =>
      'Create Facebook Marketplace post';

  @override
  String get connectedAccountsXToggleTitle => 'Create X post';

  @override
  String get connectedAccountsLinkedinToggleTitle => 'Create LinkedIn post';

  @override
  String get connectedAccountsInstagramLoadErrorMessage =>
      'Couldn\'t load your Instagram accounts.';

  @override
  String get connectedAccountsAvatarFallbackName => 'Instagram';

  @override
  String get connectedAccountsDisconnectingToastLabel => 'Disconnecting';

  @override
  String get connectedAccountsDisconnectedToastMessage =>
      'Instagram account disconnected.';

  @override
  String get connectedAccountsFallbackAccountName => 'Instagram account';

  @override
  String connectedAccountsDisconnectSemanticsLabel(String name) {
    return 'Disconnect $name';
  }

  @override
  String get connectedAccountsDisconnectButtonLabel => 'Disconnect';

  @override
  String connectedAccountsPostsStatLabel(int count) {
    return 'Posts $count';
  }

  @override
  String connectedAccountsFollowersStatLabel(int count) {
    return 'Followers $count';
  }

  @override
  String connectedAccountsFollowingStatLabel(int count) {
    return 'Following $count';
  }

  @override
  String get connectedAccountsConnectButtonLabel => 'Connect Instagram';

  @override
  String get connectedAccountsOpeningBrowserToastMessage =>
      'Opening Instagram sign-in in your browser.';

  @override
  String get connectedAccountsLinkCopiedToastMessage =>
      'Couldn\'t open your browser — Instagram sign-in link copied instead. Paste it into your browser to connect.';

  @override
  String get connectedAccountsConnectionFailedToastMessage =>
      'Instagram connection failed — please try again.';

  @override
  String connectedAccountsTelegramChannelsConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels connected',
      one: '$count channel connected',
    );
    return '$_temp0';
  }

  @override
  String get connectedAccountsTelegramNoChannelsMessage =>
      'No Telegram channels connected';

  @override
  String get connectedAccountsYoutubeAddAccountLabel => 'Add account';

  @override
  String get connectedAccountsYoutubeSignOutLabel => 'Sign out';

  @override
  String connectedAccountsUnavailableSemanticsSuffix(String label) {
    return '$label (unavailable in this build)';
  }

  @override
  String get connectedAccountsYoutubeBetaNoteMessage =>
      'Beta — not available in this build.';

  @override
  String get connectedAccountsThreadsUnavailableNoteMessage =>
      'Threads posting needs a Threads profile linked to an Instagram professional account — this build never requests that permission.';

  @override
  String get connectedAccountsFacebookMarketplaceUnavailableNoteMessage =>
      'Facebook Marketplace has no compliant automation path on any platform — its listings have to be posted by hand.';

  @override
  String get connectedAccountsXUnavailableNoteMessage =>
      'X posting needs its own X API app on a paid write tier — neither is set up in this build.';

  @override
  String get connectedAccountsLinkedinUnavailableNoteMessage =>
      'LinkedIn posting needs an approved LinkedIn Marketing API app — this build has no LinkedIn credentials.';

  @override
  String get connectedAccountsConnectedStatusLabel => 'Connected';

  @override
  String get connectedAccountsNotConnectedStatusLabel => 'Not connected';

  @override
  String get connectedAccountsInstagramBrowserHint =>
      'Opens your system browser — Meta does not permit OAuth inside an in-app WebView.';

  @override
  String get connectedAccountsOtherChannelsHint =>
      'OLX has no persistent account to connect — OLX cross-posting runs from the desktop app only.';

  @override
  String get leadsCommitFieldUppercaseLabel => 'COMMIT';

  @override
  String get languageSheetTitle => 'Language';

  @override
  String get languageSheetCloseLabel => 'Close';

  @override
  String get galleryPreviousPhotoSemanticsLabel => 'Previous photo';

  @override
  String get galleryNextPhotoSemanticsLabel => 'Next photo';

  @override
  String get contactPhoneFieldHint =>
      'Uzbekistan numbers only — +998 and nine digits.';

  @override
  String get leadsPhoneFormatHint =>
      'Uzbekistan numbers only — +998 and nine digits.';

  @override
  String get filterPriceAnyOptionLabel => 'Any price';

  @override
  String agentsAdsGridActiveCountLabel(int count) {
    return '$count active';
  }

  @override
  String get permissionsPrimerLeadBody =>
      'Two permissions, asked once. You can change either of them later in Settings.';

  @override
  String get authLoginLeadBody =>
      'Sign in to save listings, message agents, and manage your business.';

  @override
  String get authRegisterLeadBody =>
      'Browsing, saving and messaging work on any account. A realtor account adds the Work tab — listings, leads and publishing.';

  @override
  String get authRegisterFullNameHint => 'Dilnoza Yusupova';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get profileSignedOutContactUsRowSubtitle =>
      'Questions, issues and suggestions';

  @override
  String get profileAgentEditProfileRowSubtitle => 'Avatar, name, phone, email';

  @override
  String get profileAgentConnectedAccountsRowSubtitle =>
      'Instagram, Telegram, YouTube';

  @override
  String get profileAgentSettingsRowSubtitle =>
      'Language, notifications, about';

  @override
  String get profileAgentMessagesRowSubtitle => 'Coming soon';

  @override
  String get profileBuyerUpdateProfileRowSubtitle =>
      'Name, phone, email, password';

  @override
  String get profileBuyerRegisterAsAgentRowSubtitle =>
      'Opens a Google Form in your browser';

  @override
  String get settingsConnectedAccountsRowSubtitle =>
      'Instagram, Telegram, YouTube';

  @override
  String get settingsLogoutRowSubtitle => 'You will need to sign in again';

  @override
  String get editProfilePasswordHelper =>
      'At least 6 characters. Only needed if you are changing it.';

  @override
  String get sharedLoadMoreLoadingLabel => 'Loading more…';

  @override
  String get leadsKanbanLongPressHint => 'Long-press a card to move it';

  @override
  String leadsCallBackFlagLabel(String when) {
    return 'Call back $when';
  }

  @override
  String get leadsOptionalFieldHint => 'Optional';

  @override
  String leadsMoveToContextLine(String name, String status) {
    return '$name is in $status.';
  }
}
