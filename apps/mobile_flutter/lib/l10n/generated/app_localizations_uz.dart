// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get settingsScreenTitle => 'Sozlamalar';

  @override
  String get settingsNavBackLabel => 'Orqaga';

  @override
  String get settingsLanguageRowTitle => 'Til';

  @override
  String get settingsConnectedAccountsRowTitle => 'Ulangan hisoblar';

  @override
  String get settingsAboutRowTitle => 'Ilova haqida';

  @override
  String settingsAboutRowSubtitle(String version) {
    return 'Versiya $version';
  }

  @override
  String settingsAboutToastMessage(String appName, String version) {
    return '$appName $version';
  }

  @override
  String get settingsSessionGroupLabel => 'Sessiya';

  @override
  String get settingsLogoutRowTitle => 'Chiqish';

  @override
  String get settingsLoggingOutLabel => 'Chiqilmoqda…';

  @override
  String get settingsSignOutTokenNotClearedMessage =>
      'Tizimdan chiqildi, lekin ushbu qurilmadagi saqlangan sessiya o‘chirilmadi. Qurilmani boshqa birovga berishdan oldin qayta tizimdan chiqing yoki ilovani o‘chiring.';

  @override
  String get settingsNotificationsRowTitle => 'Bildirishnomalar';

  @override
  String get settingsNotificationsRowSubtitle =>
      'Hali yuborilmaydi — push-bildirishnomalar ushbu versiyada ulanmagan.';

  @override
  String get settingsNotificationsToggleLabel => 'Bildirishnomalar tugmasi';

  @override
  String get homeLocationPillLabel => 'Toshkent, O\'zbekiston';

  @override
  String homeNotificationsBellSemanticLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bildirishnomalar, $count tasi o\'qilmagan',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchIconSemanticLabel => 'Qidiruv';

  @override
  String get homeAgentPitchHeading => 'Siz rieltormisiz?';

  @override
  String get homeAgentPitchSubtitle =>
      'E\'lonlaringiz, lidlaringiz va jamoangizni bitta ilovada boshqaring.';

  @override
  String get homeAgentPitchButtonLabel => 'Boshlash';

  @override
  String get homeCategoryAllLabel => 'Barchasi';

  @override
  String get homeCategoryApartmentLabel => 'Kvartira';

  @override
  String get homeCategoryHouseLabel => 'Uy';

  @override
  String get homeCategoryOfficeLabel => 'Ofis';

  @override
  String get homeCategoryRetailLabel => 'Savdo maydoni';

  @override
  String get homeExploreNearbySectionTitle => 'Yaqin atrofda';

  @override
  String get homeFeaturedListingsSectionTitle => 'Tavsiya etilgan e\'lonlar';

  @override
  String get homeFeaturedListingsViewAllLabel => 'Barchasini ko\'rish';

  @override
  String get homeFeaturedListingsRetryMessage => 'E\'lonlarni yuklab bo\'lmadi';

  @override
  String get homeFeedEmptyMessage => 'Hozircha e\'lonlar mavjud emas.';

  @override
  String get homePromoOneTitle => 'Bitta post,\nHar bir kanalda';

  @override
  String get homePromoOneSubtitle => 'Instagram, Telegram va YouTube';

  @override
  String get homePromoTwoTitle => 'Yashnobodda\nyangi';

  @override
  String get homePromoTwoSubtitle =>
      '4 xonali yangi binolar \$95,000 dan boshlab';

  @override
  String get homeTopAgentsSectionTitle => 'Top rieltorlar';

  @override
  String get homeTopAgentsExploreLinkLabel => 'Ko\'rish';

  @override
  String get homeTopAgentsRetryMessage => 'Rieltorlarni yuklab bo\'lmadi';

  @override
  String homeAgentAdsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta e\'lon',
    );
    return '$_temp0';
  }

  @override
  String get homeTopDistrictsSectionTitle => 'Top tumanlar';

  @override
  String get homeTopDistrictsExploreLinkLabel => 'Ko\'rish';

  @override
  String get homeDistrictChilonzorName => 'Chilonzor';

  @override
  String get homeDistrictYunusobodName => 'Yunusobod';

  @override
  String get homeDistrictSergeliName => 'Sergeli';

  @override
  String get homeDistrictMirobodName => 'Mirobod';

  @override
  String get searchScreenTitle => 'Qidiruv';

  @override
  String get searchInputHint =>
      'Shahar, tuman yoki sarlavha bo\'yicha qidiring';

  @override
  String get searchCancelButtonLabel => 'Bekor qilish';

  @override
  String get searchFiltersButtonLabel => 'Filtrlar';

  @override
  String get searchSortHighestPriceLabel => 'Yuqori narx';

  @override
  String get searchSortLowestPriceLabel => 'Past narx';

  @override
  String get searchSortNewestLabel => 'Yangi';

  @override
  String get searchResultsRetryMessage => 'E\'lonlarni yuklab bo\'lmadi.';

  @override
  String get searchResultsEmptyMessage => 'E\'lonlar topilmadi.';

  @override
  String get searchRecentSearchesSectionTitle => 'So\'nggi qidiruvlar';

  @override
  String get searchRecentSearchesClearLabel => 'Tozalash';

  @override
  String get filterSheetTitle => 'Filtrlar';

  @override
  String get filterCountErrorMessage =>
      'Mos e\'lonlar sonini hisoblab bo\'lmadi.';

  @override
  String get filterApplyButtonLabel => 'Filtrlarni qo\'llash';

  @override
  String filterApplyButtonWithCountLabel(int count) {
    return 'Filtrlarni qo\'llash ($count)';
  }

  @override
  String get filterResetButtonLabel => 'Qayta tiklash';

  @override
  String get filterAreaMinFieldLabel => 'Min. umumiy maydon';

  @override
  String get filterAreaMaxFieldLabel => 'Maks. umumiy maydon';

  @override
  String get filterCategoryFieldLabel => 'Kategoriya';

  @override
  String get filterTypeFieldLabel => 'Turi';

  @override
  String get filterCategoryRentOptionLabel => 'Ijara';

  @override
  String get filterCategorySaleOptionLabel => 'Sotuv';

  @override
  String get filterTypeResidentialOptionLabel => 'Turar-joy';

  @override
  String get filterTypeNonresidentialOptionLabel => 'Turar-joy bo\'lmagan';

  @override
  String get filterCityFieldLabel => 'Shahar';

  @override
  String get filterCityPickerTitle => 'Shahar';

  @override
  String get filterCityAnyOptionLabel => 'Har qanday shahar';

  @override
  String get filterDistrictFieldLabel => 'Tuman';

  @override
  String get filterDistrictPickerTitle => 'Tuman';

  @override
  String get filterDistrictAnyOptionLabel => 'Har qanday tuman';

  @override
  String get filterDistrictPickCityFirstPlaceholder => 'Avval shaharni tanlang';

  @override
  String get filterRegionsLoadingPlaceholder => 'Yuklanmoqda…';

  @override
  String get filterRegionsErrorPlaceholder => 'Yuklab bo\'lmadi';

  @override
  String get filterFurnitureFieldLabel => 'Mebel';

  @override
  String get filterRepairFieldLabel => 'Ta\'mir';

  @override
  String get filterFurnitureWithOptionLabel => 'Mebel bilan';

  @override
  String get filterFurnitureWithoutOptionLabel => 'Mebelsiz';

  @override
  String get filterRepairNotRepairedOptionLabel => 'Ta\'mirlanmagan';

  @override
  String get filterRepairNormalOptionLabel => 'Oddiy';

  @override
  String get filterRepairGoodOptionLabel => 'Yaxshi';

  @override
  String get filterRepairExcellentOptionLabel => 'A\'lo';

  @override
  String get filterPriceMinFieldLabel => 'Min. narx';

  @override
  String get filterPriceMaxFieldLabel => 'Maks. narx';

  @override
  String get filterRoomsFieldLabel => 'Xonalar';

  @override
  String get filterSortFieldLabel => 'Saralash';

  @override
  String get filterStatusFieldLabel => 'Holat';

  @override
  String get filterSortNewestOptionLabel => 'Yangi';

  @override
  String get filterSortHighestPriceOptionLabel => 'Yuqori narx';

  @override
  String get filterSortLowestPriceOptionLabel => 'Past narx';

  @override
  String get filterStatusActiveOptionLabel => 'Faol';

  @override
  String get filterStatusSoldOptionLabel => 'Sotilgan';

  @override
  String get filterStatusDraftOptionLabel => 'Qoralama';

  @override
  String get filterStoreyFieldLabel => 'Qavat';

  @override
  String get listingDescriptionSectionTitle => 'Tavsif';

  @override
  String get listingAdditionalInfoSectionTitle => 'Qo\'shimcha ma\'lumot';

  @override
  String get listingSizesSectionTitle => 'O\'lchamlar';

  @override
  String get listingNearbyPlacesSectionTitle => 'Yaqin atrofdagi joylar';

  @override
  String get listingLocationSectionTitle => 'Joylashuv';

  @override
  String get listingNotFoundMessage =>
      'Bu e\'lon endi mavjud emas.\nU sotilgan yoki o\'chirilgan bo\'lishi mumkin.';

  @override
  String get listingLoadErrorMessage => 'Bu e\'lonni yuklab bo\'lmadi.';

  @override
  String get listingAgentUnavailableLabel =>
      'Rieltor ma\'lumotlari mavjud emas';

  @override
  String listingAgentStatsLine(int adsCount, int dealsClosedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      adsCount,
      locale: localeName,
      other: 'Rieltor · $adsCount ta e\'lon · $dealsClosedCount ta yopilgan',
    );
    return '$_temp0';
  }

  @override
  String listingAgentCallSemanticsLabel(String fullName) {
    return 'Qo\'ng\'iroq qilish: $fullName';
  }

  @override
  String get listingSubmitApplicationButtonLabel => 'Ariza yuborish';

  @override
  String get listingFavouriteUpdateErrorMessage =>
      'Sevimlilarni yangilab bo\'lmadi';

  @override
  String get listingSaveThePlaceButtonLabel => 'Joyni saqlash';

  @override
  String get listingSavedButtonLabel => 'Saqlangan';

  @override
  String get listingNavBackSemanticsLabel => 'Orqaga';

  @override
  String get listingNavShareSemanticsLabel => 'Ulashish';

  @override
  String get listingLinkCopiedToastMessage =>
      'Havola ulashish uchun nusxalandi';

  @override
  String get listingNoLocationMessage =>
      'Bu e\'lon uchun joylashuv ko\'rsatilmagan.';

  @override
  String get listingAskingPriceLabel => 'So\'ralayotgan narx';

  @override
  String get listingSizesAreaLabel => 'Maydon';

  @override
  String get listingSizesRoomsLabel => 'Xonalar';

  @override
  String get listingSizesFloorLabel => 'Qavat';

  @override
  String get listingSizesTypeLabel => 'Turi';

  @override
  String get listingTourSectionTitle => '3D tur';

  @override
  String get listingTourViewSemanticsLabel => '3D turni ko\'rish';

  @override
  String get listingTourBannerLabel => 'Jonli 3D tur';

  @override
  String get listingTourInvalidLinkMessage =>
      'Bu e\'londagi 3D tur havolasi yaroqsiz.';

  @override
  String get listingTourLoadErrorMessage => '3D turni yuklab bo\'lmadi.';

  @override
  String get listingTypeResidentialLabel => 'Turar-joy';

  @override
  String get listingTypeNonresidentialLabel => 'Turar-joy bo\'lmagan';

  @override
  String get listingCategorySaleLabel => 'Sotuv';

  @override
  String get listingCategoryRentLabel => 'Ijara';

  @override
  String get listingRepairmentNotRepairedLabel => 'Ta\'mirlanmagan';

  @override
  String get listingRepairmentNormalLabel => 'O\'rtacha';

  @override
  String get listingRepairmentGoodLabel => 'Yaxshi';

  @override
  String get listingRepairmentExcellentLabel => 'A\'lo';

  @override
  String get listingFurnitureWithLabel => 'Mebel bilan';

  @override
  String get listingFurnitureWithoutLabel => 'Mebelsiz';

  @override
  String listingRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count xona',
    );
    return '$_temp0';
  }

  @override
  String get galleryEmptyStateMessage =>
      'Bu e\'lon uchun fotosuratlar mavjud emas.';

  @override
  String get galleryVideoUnsupportedMessage =>
      'Video ko\'rib chiqish hozircha galereyada mavjud emas.';

  @override
  String get galleryUnsupportedMediaMessage =>
      'Bu media turini ko\'rib chiqib bo\'lmaydi.';

  @override
  String galleryPositionSemanticsLabel(int current, int total) {
    return 'Galereyadagi o\'rni: $total tadan $current';
  }

  @override
  String galleryThumbnailSemanticsLabel(int index, int total) {
    return 'Rasm: $total tadan $index';
  }

  @override
  String get galleryCloseTooltip => 'Galereyani yopish';

  @override
  String galleryCounterSemanticsLabel(String label) {
    return 'Rasm $label';
  }

  @override
  String get mapNavBackSemanticsLabel => 'Orqaga';

  @override
  String get mapTitleLabel => 'Xarita';

  @override
  String get mapShowListSemanticsLabel => 'Ro\'yxatni ko\'rsatish';

  @override
  String mapPinnedAllCountLabel(int count) {
    return 'Xaritada $count ta';
  }

  @override
  String mapPinnedPartialCountLabel(int pinned, int total) {
    return 'Xaritada $total tadan $pinned';
  }

  @override
  String get mapFiltersButtonLabel => 'Filtrlar';

  @override
  String get mapNoLocationResultsMessage =>
      'Ushbu e\'lonlarning birortasida ham joylashuv saqlanmagan.';

  @override
  String get mapNoResultsMessage => 'Qidiruvingizga mos e\'lon topilmadi.';

  @override
  String mapClusterSemanticsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu yerda $count ta e\'lon bor, kattalashtirish uchun bosing',
    );
    return '$_temp0';
  }

  @override
  String mapPinSemanticsLabel(String title, String price) {
    return '$title, $price';
  }

  @override
  String get savedListingsNavBackSemanticsLabel => 'Orqaga';

  @override
  String get savedListingsScreenTitle => 'Saqlangan e\'lonlar';

  @override
  String get savedListingsSignInPromptMessage =>
      'Saqlangan e\'lonlaringizni ko\'rish uchun tizimga kiring.';

  @override
  String get savedListingsSignInButtonLabel => 'Kirish';

  @override
  String get savedListingsLoadErrorMessage =>
      'Saqlangan e\'lonlaringizni yuklab bo\'lmadi';

  @override
  String get savedListingsEmptyStateMessage =>
      'Siz hali birorta ham e\'lon saqlamagansiz.';

  @override
  String get sharedConfirmDialogCancelLabel => 'Bekor qilish';

  @override
  String sharedDeleteConfirmTitle(String subject) {
    return '${subject}ni o\'chirasizmi?';
  }

  @override
  String get sharedDeleteConfirmBody => 'Bu amalni bekor qilib bo\'lmaydi.';

  @override
  String get sharedDeleteConfirmDeleteLabel => 'O\'chirish';

  @override
  String get sharedDiscardChangesTitle => 'O\'zgarishlar bekor qilinsinmi?';

  @override
  String get sharedDiscardChangesBody =>
      'Saqlanmagan o\'zgarishlaringiz bor. Hozir chiqsangiz, ular saqlanmaydi.';

  @override
  String get sharedDiscardChangesDiscardLabel => 'Rad etish';

  @override
  String get sharedSignOutTitle => 'Tizimdan chiqilsinmi?';

  @override
  String get sharedSignOutBody =>
      'Hisobingizga kirish uchun qayta tizimga kirishingiz kerak bo\'ladi.';

  @override
  String get sharedSignOutConfirmLabel => 'Chiqish';

  @override
  String get sharedNoReviewsYetLabel => 'Hali sharhlar yo\'q';

  @override
  String sharedRatingLabel(String rating, int count) {
    return 'Sharh: $rating/5 ($count)';
  }

  @override
  String get sharedStatusUnknownLabel => 'Noma\'lum';

  @override
  String get sharedAdStageActiveLabel => 'Faol';

  @override
  String get sharedAdStageSoldLabel => 'Sotilgan';

  @override
  String get sharedAdStageDraftLabel => 'Qoralama';

  @override
  String get sharedLeadStatusNewLabel => 'Yangi';

  @override
  String get sharedLeadStatusCouldNotConnectLabel => 'Bog\'lanib bo\'lmadi';

  @override
  String get sharedLeadStatusNeedToCallBackLabel =>
      'Qayta qo\'ng\'iroq qilish kerak';

  @override
  String get sharedLeadStatusRejectedLabel => 'Rad etilgan';

  @override
  String get sharedLeadStatusAcceptedLabel => 'Qabul qilingan';

  @override
  String get sharedPublishStatusPendingLabel => 'E\'lon qilinmagan';

  @override
  String get sharedPublishStatusAwaitingReviewLabel => 'Ko\'rib chiqilmoqda';

  @override
  String get sharedPublishStatusPublishedLabel => 'E\'lon qilindi';

  @override
  String get sharedPublishStatusFailedLabel => 'Xatolik';

  @override
  String get sharedGenericErrorMessage => 'Nimadir xato ketdi.';

  @override
  String get sharedShowPasswordLabel => 'Parolni ko\'rsatish';

  @override
  String get sharedHidePasswordLabel => 'Parolni yashirish';

  @override
  String get sharedChangePhotoLabel => 'Rasmni o\'zgartirish';

  @override
  String get sharedMediaSourceCloseLabel => 'Yopish';

  @override
  String get sharedMediaSourceCameraLabel => 'Kamera';

  @override
  String get sharedMediaSourceGalleryLabel => 'Kutubxonadan tanlash';

  @override
  String get sharedNavRowBackLabel => 'Orqaga';

  @override
  String get sharedNavRowCloseLabel => 'Yopish';

  @override
  String sharedDialFallbackToastMessage(String phone) {
    return 'Terish ilovasi ochilmadi — telefon raqami nusxalandi: $phone';
  }

  @override
  String get sharedFavouriteUpdateFailedMessage =>
      'Sevimlilarni yangilab bo\'lmadi';

  @override
  String get sharedLoadMoreFailedLabel =>
      'Ko\'proq yuklab bo\'lmadi — Qayta urinish';

  @override
  String get sharedRetryLabel => 'Qayta urinish';

  @override
  String get sharedListingCardSaleBadgeLabel => 'Sotuv';

  @override
  String get sharedListingCardRentBadgeLabel => 'Ijara';

  @override
  String sharedRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count xona',
    );
    return '$_temp0';
  }

  @override
  String get navTabHomeLabel => 'Bosh sahifa';

  @override
  String get navTabSearchLabel => 'Qidiruv';

  @override
  String get navTabWorkLabel => 'Ish';

  @override
  String get navTabAgentsLabel => 'Rieltorlar';

  @override
  String get navTabProfileLabel => 'Profil';

  @override
  String get permissionsHeaderTitle =>
      'La Casa uchun quyidagilarga ruxsat bering…';

  @override
  String get permissionsCameraRowTitle => 'Kamera va fotosuratlar';

  @override
  String get permissionsCameraRowBody =>
      'E\'lonlaringiz va profil rasmingizga fotosurat qo\'shish uchun';

  @override
  String get permissionsNotificationsRowTitle => 'Bildirishnomalar';

  @override
  String get permissionsNotificationsRowBody =>
      'Yangi lidlar va e\'lon qilish holati haqida xabar berish uchun.';

  @override
  String get permissionsNotNowButtonLabel => 'Hozir emas';

  @override
  String get permissionsContinueButtonLabel => 'Davom etish';

  @override
  String get permissionsAllowButtonLabel => 'Ruxsat berish';

  @override
  String get permissionsAllowedStatusLabel => 'Ruxsat berildi';

  @override
  String get permissionsLimitedStatusLabel =>
      'Ruxsat berildi — faqat tanlangan fotosuratlar bilan cheklangan. Ko\'proq tanlash uchun bosing.';

  @override
  String get permissionsDeniedStatusLabel =>
      'Ruxsat berilmagan — buni tizim sozlamalarida o\'zgartirishingiz mumkin';

  @override
  String get permissionsPermanentlyDeniedStatusLabel =>
      'Ruxsat berilmagan — tizim sozlamalarini ochish uchun bosing';

  @override
  String get permissionsUnavailableStatusLabel =>
      'Bu versiyada hali mavjud emas';

  @override
  String get onboardingSkipButtonLabel => 'O\'tkazib yuborish';

  @override
  String get onboardingNextButtonLabel => 'Keyingisi';

  @override
  String get onboardingGetStartedButtonLabel => 'Boshlash';

  @override
  String get onboardingSlideOneTitle =>
      'Barcha e\'lonlaringizni bir joyda boshqaring';

  @override
  String get onboardingSlideOneBody =>
      'Barcha e\'lonlaringizni tartibli va oson topiladigan holda, bitta ilovada saqlang.';

  @override
  String get onboardingSlideTwoTitle =>
      'Bir vaqtning o\'zida barcha kanallarga ulashing';

  @override
  String get onboardingSlideTwoBody =>
      'Ilovadan chiqmasdan Instagram, Telegram va boshqa kanallarga e\'lon joylashtiring.';

  @override
  String get onboardingSlideThreeTitle =>
      'Lidlarni birinchi murojaatdan bitim yopilgunga qadar kuzating';

  @override
  String get onboardingSlideThreeBody =>
      'Har bir so\'rovni saralang va nazorat qiling — hech biri e\'tibordan chetda qolmasin.';

  @override
  String get listingEditorCreateNavTitle => 'Yangi e\'lon qo\'shish';

  @override
  String get listingEditorEditNavTitle => 'E\'lonni yangilash';

  @override
  String get listingEditorPublishStatusNavTitle => 'E\'lon qilish holati';

  @override
  String get listingEditorWizardBackLabel => 'Orqaga';

  @override
  String get listingEditorWizardNextLabel => 'Keyingi';

  @override
  String get listingEditorWizardCreateLabel => 'Yaratish';

  @override
  String get listingEditorStepBasicsLabel => 'Asosiy';

  @override
  String get listingEditorStepDetailsLabel => 'Tafsilotlar';

  @override
  String get listingEditorStepPhotosLabel => 'Fotosuratlar';

  @override
  String get listingEditorStepPublishLabel => 'E\'lon qilish';

  @override
  String get listingEditorCreatePublishNoticeMessage =>
      'E\'lon qilish ushbu e\'lon yaratilgandan so\'ng mavjud bo\'ladi — \"Yaratish\"ni bosing, so\'ngra e\'lonning tahrirlash ekranidagi har bir kanal uchun tugmalardan foydalaning.';

  @override
  String get listingEditorPendingUploadsMessage =>
      'Fotosurat/video yuklanib bo\'lguncha kuting.';

  @override
  String get listingEditorCreatePendingLabel => 'Yaratilmoqda';

  @override
  String get listingEditorCreateSuccessMessage => 'Muvaffaqiyatli yaratildi';

  @override
  String get listingEditorUpdatePendingLabel => 'Yangilanmoqda';

  @override
  String get listingEditorUpdateSuccessMessage => 'Muvaffaqiyatli yangilandi';

  @override
  String get listingEditorDeletePendingLabel => 'O\'chirilmoqda';

  @override
  String get listingEditorDeleteSuccessMessage => 'E\'lon o\'chirildi';

  @override
  String get listingEditorGenericErrorMessage => 'Nimadir xato ketdi.';

  @override
  String get listingEditorNetworkErrorMessage =>
      'Internet aloqasi yo\'q. Tarmog\'ingizni tekshirib, qayta urinib ko\'ring.';

  @override
  String get listingEditorLoadErrorMessage =>
      'Ushbu e\'lonni yuklab bo\'lmadi.';

  @override
  String get listingEditorDeleteConfirmSubject => 'e\'lon';

  @override
  String get listingEditorTitleFieldLabel => 'Sarlavha';

  @override
  String get listingEditorCityFieldLabel => 'Shahar';

  @override
  String get listingEditorDistrictFieldLabel => 'Tuman';

  @override
  String get listingEditorDistrictDisabledHint => 'Avval shaharni tanlang';

  @override
  String get listingEditorAddressFieldLabel => 'Manzil';

  @override
  String get listingEditorReferenceFieldLabel => 'Mo\'ljal';

  @override
  String get listingEditorReferenceHint => 'Yo\'nalish / mo\'ljal';

  @override
  String get listingEditorTypeFieldLabel => 'Turi';

  @override
  String get listingEditorCategoryFieldLabel => 'Toifa';

  @override
  String get listingEditorRepairFieldLabel => 'Ta\'mir';

  @override
  String get listingEditorFurnitureFieldLabel => 'Mebel';

  @override
  String get listingEditorPriceTypeFieldLabel => 'Valyuta turi';

  @override
  String get listingEditorStatusFieldLabel => 'Holat';

  @override
  String get listingEditorRoomsFieldLabel => 'Xonalar';

  @override
  String get listingEditorAreaFieldLabel => 'Maydon';

  @override
  String get listingEditorAreaUnitSuffix => 'm²';

  @override
  String get listingEditorStoreyFieldLabel => 'Qavat';

  @override
  String get listingEditorFloorsFieldLabel => 'Qavatlar soni';

  @override
  String get listingEditorHashtagsFieldLabel => 'Xeshteglar';

  @override
  String get listingEditorHashtagsHint => '#new #2024';

  @override
  String get listingEditorPriceFieldLabel => 'Narx';

  @override
  String get listingEditorDescriptionFieldLabel => 'Tavsif';

  @override
  String get listingEditorTypeResidentialOption => 'Turar-joy';

  @override
  String get listingEditorTypeNonresidentialOption => 'G\'ayri turar-joy';

  @override
  String get listingEditorCategoryRentOption => 'Ijara';

  @override
  String get listingEditorCategorySaleOption => 'Sotuv';

  @override
  String get listingEditorRepairNotRepairedOption => 'Ta\'mirlanmagan';

  @override
  String get listingEditorRepairNormalOption => 'O\'rtacha';

  @override
  String get listingEditorRepairGoodOption => 'Yaxshi';

  @override
  String get listingEditorRepairExcellentOption => 'A\'lo';

  @override
  String get listingEditorFurnitureWithOption => 'Mebel bilan';

  @override
  String get listingEditorFurnitureWithoutOption => 'Mebelsiz';

  @override
  String get listingEditorPriceTypeUzsOption => 'so\'m';

  @override
  String get listingEditorPriceTypeUsdOption => 'y.e';

  @override
  String get listingEditorStageActiveOption => 'Faol';

  @override
  String get listingEditorStageSoldOption => 'Sotilgan';

  @override
  String get listingEditorStageDraftOption => 'Qoralama';

  @override
  String get listingEditorPricePreviewPlaceholder =>
      'Ko\'rib chiqish uchun narxni kiriting.';

  @override
  String listingEditorPricePreviewText(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get listingEditorNearbyPlacesLabel => 'Yaqin-atrofdagi joylar';

  @override
  String get listingEditorNearbyPlacesHint =>
      'masalan, Chilonzor metro bekati (7 daqiqa yurish)';

  @override
  String get listingEditorNearbyPlacesAddButtonLabel => 'Qo\'shish';

  @override
  String get listingEditorAdditionalInfoLabel => 'Qo\'shimcha ma\'lumot';

  @override
  String get listingEditorAdditionalInfoAddButtonLabel => 'Qo\'shish';

  @override
  String get listingEditorAdditionalInfoKeyHint => 'Kalit';

  @override
  String get listingEditorAdditionalInfoValueHint => 'Qiymat';

  @override
  String get listingEditorNoExistingPhotosMessage =>
      'Ushbu e\'londa hali fotosuratlar yo\'q.';

  @override
  String get listingEditorExistingPhotosLabel => 'Mavjud fotosuratlar';

  @override
  String get listingEditorAddPhotosLabel => 'Fotosurat qo\'shish';

  @override
  String get listingEditorAddPhotosButtonLabel => 'Fotosurat qo\'shish';

  @override
  String get listingEditorAddVideoButtonLabel => 'Video qo\'shish';

  @override
  String get listingEditorMediaLimitsHint =>
      '5 tagacha rasm (har biri 5MB gacha). Ixtiyoriy bitta video, 70MB gacha.';

  @override
  String get listingEditorAddPhotoSheetTitle => 'Fotosurat qo\'shish';

  @override
  String get listingEditorAddVideoSheetTitle => 'Video qo\'shish';

  @override
  String get listingEditorVideoFallbackFileName => 'Video';

  @override
  String get listingEditorUploadFailedFallbackMessage =>
      'Yuklab bo\'lmadi. Qayta urinib ko\'ring.';

  @override
  String get listingEditorUploadedStatusLabel => 'Yuklandi';

  @override
  String listingEditorUploadingProgressLabel(int percent) {
    return 'Yuklanmoqda… $percent%';
  }

  @override
  String get listingEditorPublishSectionLabel => 'E\'lon qilish';

  @override
  String get listingEditorChannelInstagramLabel => 'Instagram';

  @override
  String get listingEditorChannelTelegramLabel => 'Telegram';

  @override
  String get listingEditorChannelYoutubeLabel => 'YouTube';

  @override
  String get listingEditorChannelOlxLabel => 'OLX';

  @override
  String get listingEditorChannelRealtingLabel => 'Realting';

  @override
  String get listingEditorChannelUnknownLabel => 'Noma\'lum kanal';

  @override
  String get listingEditorYoutubeUnavailableHint =>
      'Beta — ushbu versiyada mavjud emas.';

  @override
  String get listingEditorOlxUnavailableHint =>
      'OLX\'ga chop etish faqat desktop ilovasida mavjud (brauzer kengaytmasi talab qilinadi).';

  @override
  String get listingEditorPublishStatusLinkLabel => 'E\'lon qilish holati';

  @override
  String get listingEditorPublishChannelsSheetTitle =>
      'E\'lon qilmoqchi bo\'lgan kanallaringizni tanlang!';

  @override
  String get listingEditorInstagramLoadErrorMessage =>
      'Ulangan Instagram hisoblarini yuklab bo\'lmadi.';

  @override
  String get listingEditorNoInstagramAccountMessage =>
      'Hech qanday Instagram hisobi ulanmagan. Sozlamalarda ulashingiz yoki postni o\'zingiz qoralashingiz mumkin.';

  @override
  String get listingEditorNoTelegramChannelMessage =>
      'Hech qanday Telegram kanali ulanmagan.';

  @override
  String listingEditorTelegramChannelRowLabel(int chatId) {
    return 'Telegram kanali #$chatId';
  }

  @override
  String get listingEditorCancelButtonLabel => 'Bekor qilish';

  @override
  String get listingEditorPublishButtonLabel => 'E\'lon qilish';

  @override
  String listingEditorInstagramPublishFailedMessage(String usernames) {
    return 'Instagram\'da e\'lon qilish quyidagilar uchun amalga oshmadi: $usernames';
  }

  @override
  String get listingEditorInstagramPublishSuccessMessage =>
      'Instagram post e\'lon qilindi!';

  @override
  String listingEditorTelegramPublishFailedMessage(String chatIds) {
    return 'Telegram\'da e\'lon qilish quyidagilar uchun amalga oshmadi: $chatIds';
  }

  @override
  String get listingEditorTelegramPublishSuccessMessage =>
      'Telegram post e\'lon qilindi!';

  @override
  String get listingEditorPublishStatusLoadErrorMessage =>
      'E\'lon qilish holatini yuklab bo\'lmadi.';

  @override
  String get listingEditorOlxNotAvailableLabel => 'Mobilda mavjud emas';

  @override
  String listingEditorLastAttemptLabel(String date) {
    return 'Oxirgi urinish: $date';
  }

  @override
  String get listingEditorViewPostLinkLabel => 'Postni ko\'rish';

  @override
  String get listingEditorPostLinkCopiedMessage =>
      'Post havolasi buferga nusxalandi.';

  @override
  String get listingEditorYoutubeNonRetryableReason =>
      'YouTube uchun qayta urinish mumkin bo\'lgan server tomonidagi chaqiruv yo\'q — yuklash brauzerda, sizning shaxsiy Google seansingiz orqali amalga oshiriladi. Qayta yuklab, natijani xabar qiling.';

  @override
  String get listingEditorOlxNonRetryableReason =>
      'OLX\'ga joylashtirish brauzer kengaytmasi orqali amalga oshiriladi, bunda odam ko\'rib chiqib \"E\'lon qilish\"ni bosadi. Buning o\'rniga kengaytmadan qayta urinib ko\'ring.';

  @override
  String get listingEditorRealtingNonRetryableReason =>
      'Realting\'dagi e\'lonlar rejalashtirilgan feed orqali sinxronlanadi, har bir e\'lon uchun alohida chaqiruv orqali emas. Bu yerda qayta urinish uchun hech narsa yo\'q.';

  @override
  String get listingEditorUnknownChannelReason =>
      'Noma\'lum e\'lon qilish kanali.';

  @override
  String listingEditorRetrySuccessMessage(String channel) {
    return '$channel uchun qayta e\'lon qilish muvaffaqiyatli amalga oshirildi.';
  }

  @override
  String get listingEditorSaveButtonLabel => 'Saqlash';

  @override
  String get listingEditorDeleteButtonLabel => 'O\'chirish';

  @override
  String get listingEditorTitleRequiredError => 'Sarlavha talab qilinadi';

  @override
  String get listingEditorCityRequiredError => 'Shahar talab qilinadi';

  @override
  String get listingEditorDistrictRequiredError => 'Tuman talab qilinadi';

  @override
  String get listingEditorAddressRequiredError => 'Manzil talab qilinadi';

  @override
  String get listingEditorReferenceRequiredError => 'Mo\'ljal talab qilinadi';

  @override
  String get listingEditorDescriptionRequiredError => 'Tavsif talab qilinadi';

  @override
  String get myListingsNavTitle => 'Mening e\'lonlarim';

  @override
  String get myListingsFilterButtonLabel => 'Filtr';

  @override
  String get myListingsCreateButtonSemanticsLabel => 'Yangi e\'lon yaratish';

  @override
  String get myListingsLoadErrorMessage => 'E\'lonlaringizni yuklab bo\'lmadi.';

  @override
  String get myListingsEmptyStateMessage => 'E\'lonlar topilmadi.';

  @override
  String get myListingsEditButtonSemanticsLabel => 'Tahrirlash';

  @override
  String get agentsDirectoryScreenTitle => 'Rieltorlar';

  @override
  String get agentsDirectoryLoadErrorMessage => 'Rieltorlarni yuklab bo\'lmadi';

  @override
  String get agentsDirectoryEmptyMessage => 'Rieltorlar topilmadi.';

  @override
  String agentsCardAdsCountLabel(int count) {
    return 'E\'lonlar: $count';
  }

  @override
  String get agentsProfileNavBackLabel => 'Orqaga';

  @override
  String get agentsProfileScreenTitle => 'Rieltor haqida ma\'lumot';

  @override
  String get agentsProfileLoadErrorMessage => 'Rieltorni yuklab bo\'lmadi';

  @override
  String get agentsProfileNotFoundMessage => 'Bu rieltor endi mavjud emas.';

  @override
  String get agentsProfileGoBackLabel => 'Orqaga qaytish';

  @override
  String get agentsInfoFullNameLabel => 'To\'liq ism:';

  @override
  String get agentsInfoEmailLabel => 'Email:';

  @override
  String get agentsInfoPhoneLabel => 'Telefon:';

  @override
  String get agentsInfoAddressLabel => 'Manzil:';

  @override
  String get agentsInfoCallButtonLabel => 'Qo\'ng\'iroq';

  @override
  String get agentsInfoMessageButtonLabel => 'Xabar';

  @override
  String get agentsAdsGridLoadErrorMessage =>
      'Rieltorning e\'lonlarini yuklab bo\'lmadi';

  @override
  String get agentsAdsGridEmptyMessage => 'E\'lonlar topilmadi.';

  @override
  String get agentsAdsGridHeading => 'E\'lonlar ro\'yxati';

  @override
  String agentsAdsGridHeadingWithCount(int count) {
    return 'E\'lonlar ro\'yxati ($count)';
  }

  @override
  String get reviewsRatingRequiredError => 'Iltimos, reyting tanlang.';

  @override
  String get reviewsUpdateSuccessToast => 'Sharh yangilandi.';

  @override
  String get reviewsPostSuccessToast => 'Sharh joylandi.';

  @override
  String get reviewsDeleteSuccessToast => 'Sharh o\'chirildi.';

  @override
  String get reviewsSelfReviewForbiddenError =>
      'O\'zingizga sharh qoldira olmaysiz.';

  @override
  String get reviewsAgentNotFoundError => 'Bu rieltor endi mavjud emas.';

  @override
  String get reviewsSaveGenericErrorMessage =>
      'Sharhingizni hozircha saqlab bo\'lmadi. Qaytadan urinib ko\'ring.';

  @override
  String get reviewsNetworkErrorMessage =>
      'Internet aloqasi yo\'q. Tarmog\'ingizni tekshirib, qaytadan urinib ko\'ring.';

  @override
  String get reviewsSheetEditTitle => 'Sharhingizni tahrirlash';

  @override
  String get reviewsSheetLeaveTitle => 'Sharh qoldirish';

  @override
  String get reviewsSheetCloseLabel => 'Yopish';

  @override
  String reviewsSheetPromptMessage(String agentName) {
    return '$agentName bilan ishlash tajribangizni baham ko\'ring.';
  }

  @override
  String get reviewsSheetCommentLabel => 'IZOH (IXTIYORIY)';

  @override
  String get reviewsSheetCommentHint =>
      'Bu rieltor bilan ishlash qanday kechdi?';

  @override
  String get reviewsSheetUpdateButtonLabel => 'Sharhni yangilash';

  @override
  String get reviewsSheetPostButtonLabel => 'Sharhni joylash';

  @override
  String get reviewsSheetDeletingLabel => 'O\'chirilmoqda…';

  @override
  String get reviewsSheetDeleteButtonLabel => 'Sharhni o\'chirish';

  @override
  String reviewsSectionHeading(int count) {
    return 'Sharhlar ($count)';
  }

  @override
  String get reviewsSectionLoadErrorMessage =>
      'Rieltorning sharhlarini yuklab bo\'lmadi';

  @override
  String get reviewsSectionEmptyMessage => 'Hozircha sharhlar yo\'q.';

  @override
  String get reviewsSectionSignInPromptMessage =>
      'Sharh qoldirish uchun tizimga kiring.';

  @override
  String get reviewsSectionSignInButtonLabel => 'Kirish';

  @override
  String get reviewsSectionSelfProfileMessage =>
      'O\'zingizning profilingizga sharh qoldira olmaysiz.';

  @override
  String get reviewsSectionLeaveButtonLabel => 'Sharh qoldirish';

  @override
  String get reviewsSectionEditButtonLabel => 'Sharhingizni tahrirlash';

  @override
  String get reviewsSectionLoadMoreLabel => 'Ko\'proq sharhlarni ko\'rsatish';

  @override
  String get profileAgentScreenTitle => 'Profil';

  @override
  String get profileAgentAccountGroupLabel => 'Hisob';

  @override
  String get profileAgentEditProfileRowTitle => 'Profilni tahrirlash';

  @override
  String get profileAgentConnectedAccountsRowTitle => 'Ulangan hisoblar';

  @override
  String get profileAgentSettingsRowTitle => 'Sozlamalar';

  @override
  String get profileAgentMessagesRowTitle => 'Xabarlar';

  @override
  String get profileAgentLanguageRowTitle => 'Til';

  @override
  String get profileAgentSessionGroupLabel => 'Sessiya';

  @override
  String get profileAgentLogoutRowTitle => 'Chiqish';

  @override
  String get profileBuyerScreenTitle => 'Profil';

  @override
  String get profileBuyerAccountGroupLabel => 'Hisob';

  @override
  String get profileBuyerSavedListingsRowTitle => 'Saqlangan e\'lonlar';

  @override
  String get profileBuyerUpdateProfileRowTitle => 'Profilni yangilash';

  @override
  String get profileBuyerLanguageRowTitle => 'Til';

  @override
  String get profileBuyerRegisterAsAgentRowTitle =>
      'Rieltor sifatida ro\'yxatdan o\'tish';

  @override
  String get profileBuyerSessionGroupLabel => 'Sessiya';

  @override
  String get profileBuyerLogoutRowTitle => 'Chiqish';

  @override
  String get profileBuyerRegisterLinkCopiedToast =>
      'Brauzeringizni ochib bo\'lmadi — buning o\'rniga ro\'yxatdan o\'tish shakli havolasi nusxalandi. Ariza berish uchun uni brauzeringizga joylashtiring.';

  @override
  String get profileSignedOutScreenTitle => 'Profil';

  @override
  String get profileSignedOutPreferencesGroupLabel => 'Afzalliklar';

  @override
  String get profileSignedOutLanguageRowTitle => 'Til';

  @override
  String get profileSignedOutContactUsRowTitle => 'Biz bilan bog\'laning';

  @override
  String get profileSignedOutPromptMessage =>
      'E\'lonlarni saqlash, rieltorlarga xabar yozish va biznesingizni boshqarish uchun tizimga kiring.';

  @override
  String get profileSignedOutSignInButtonLabel => 'Kirish';

  @override
  String get profileSignedOutSignUpButtonLabel => 'Ro\'yxatdan o\'tish';

  @override
  String get authLoginRequiredFieldsError =>
      'Majburiy maydonlar to\'ldirilmagan';

  @override
  String get authLoginSuccessToast =>
      'Foydalanuvchi muvaffaqiyatli tizimga kirdi.';

  @override
  String get authLoginInvalidCredentialsError => 'Email yoki parol noto\'g\'ri';

  @override
  String get authLoginNetworkErrorMessage =>
      'Internet aloqasi yo\'q. Tarmog\'ingizni tekshirib, qaytadan urinib ko\'ring.';

  @override
  String get authLoginGenericErrorMessage => 'Nimadir xato ketdi';

  @override
  String get authLoginWelcomeHeading => 'Xush kelibsiz';

  @override
  String get authLoginEmailFieldLabel => 'Email';

  @override
  String get authLoginPasswordFieldLabel => 'Parol';

  @override
  String get authLoginSubmitButtonLabel => 'Kirish';

  @override
  String get authLoginFooterLinkText => 'Hisobingiz yo\'qmi?';

  @override
  String get authRegisterHeading => 'Hisobingizni yarating';

  @override
  String get authRegisterAccountTypeLabel =>
      'Men quyidagi sifatda ro\'yxatdan o\'taman';

  @override
  String get authRegisterBuyerCardTitle => 'Xaridor';

  @override
  String get authRegisterBuyerCardSubtitle => 'Uylarni ko\'rish va saqlash';

  @override
  String get authRegisterRealtorCardTitle => 'Rieltor';

  @override
  String get authRegisterRealtorCardSubtitle =>
      'E\'lon joylang, mijozlar bilan ishlang';

  @override
  String get authRegisterFullNameFieldLabel => 'To\'liq ism';

  @override
  String get authRegisterPhoneFieldLabel => 'Telefon raqami';

  @override
  String get authRegisterEmailFieldLabel => 'Email';

  @override
  String get authRegisterPasswordFieldLabel => 'Parol';

  @override
  String get authRegisterPasswordHint => 'Kamida 6 ta belgi';

  @override
  String get authRegisterRealtorTypeLabel => 'Rieltor turi';

  @override
  String get authRegisterSoloAgentChipLabel => 'Yakka rieltor';

  @override
  String get authRegisterAgencyChipLabel => 'Agentlik';

  @override
  String get authRegisterSoloAgentHint =>
      'Siz o\'z nomingiz ostida ishlaysiz. Ish maydoningiz Statistika bo\'limi bilan ochiladi — o\'z e\'lonlaringiz va mijozlaringiz bilan; Hamkasblar esa siz agentlikka o\'tmaguningizcha yashirin turadi.';

  @override
  String get authRegisterAgencyNameFieldLabel => 'Agentlik nomi';

  @override
  String get authRegisterAgencyNameHelperText =>
      'Jamoa e\'lonlarida rieltorning o\'z ismi o\'rniga shu ko\'rsatiladi.';

  @override
  String get authRegisterOfficePhoneFieldLabel => 'Ofis telefoni';

  @override
  String get authRegisterTeamSizeLabel => 'Jamoa hajmi';

  @override
  String get authRegisterTeamSizeJustMeLabel => 'Hozircha faqat men';

  @override
  String get authRegisterTeamSizeTwoToFiveLabel => '2–5';

  @override
  String get authRegisterTeamSizeSixToFifteenLabel => '6–15';

  @override
  String get authRegisterTeamSizeSixteenPlusLabel => '16+';

  @override
  String get authRegisterAgencyOwnerHint =>
      'Siz agentlik egasi sifatida ro\'yxatdan o\'tasiz: hamkasblarni taklif qiling, ularga mijozlarni biriktiring va butun jamoaning statistikasini ko\'ring. Hamkasblar esa faqat siz biriktirgan narsalarni ko\'radi.';

  @override
  String get authRegisterVerificationCalloutMessage =>
      'Rieltor hisoblari Ish bo\'limi ochilishidan oldin tekshiriladi. Yuqoridagi raqamga qo\'ng\'iroq qilamiz — odatda bir ish kuni ichida.';

  @override
  String get authRegisterRequiredFieldsError =>
      'Majburiy maydonlar to\'ldirilmagan';

  @override
  String get authRegisterInvalidPhoneError =>
      'Telefon raqami formati noto\'g\'ri';

  @override
  String get authRegisterRealtorSuccessToast =>
      'Hisob yaratildi. Tez orada rieltor profilingizni tekshiramiz.';

  @override
  String get authRegisterBuyerSuccessToast =>
      'Foydalanuvchi muvaffaqiyatli yaratildi.';

  @override
  String get authRegisterNetworkErrorMessage =>
      'Internet aloqasi yo\'q. Tarmog\'ingizni tekshirib, qaytadan urinib ko\'ring.';

  @override
  String get authRegisterGenericErrorMessage => 'Nimadir xato ketdi';

  @override
  String get authRegisterRealtorSubmitButtonLabel =>
      'Rieltor hisobini yaratish';

  @override
  String get authRegisterBuyerSubmitButtonLabel => 'Ro\'yxatdan o\'tish';

  @override
  String get authRegisterFooterLinkText => 'Hisobingiz bormi? Kirish';

  @override
  String get authVisibilityToggleShowLabel => 'Parolni ko\'rsatish';

  @override
  String get authVisibilityToggleHideLabel => 'Parolni yashirish';

  @override
  String get authCloseButtonLabel => 'Yopish';

  @override
  String get editProfileScreenTitle => 'Profilni tahrirlash';

  @override
  String get editProfileDiscardDialogTitle => 'O\'zgarishlar bekor qilinsinmi?';

  @override
  String get editProfileDiscardDialogCancelButtonLabel => 'Bekor qilish';

  @override
  String get editProfileDiscardDialogConfirmButtonLabel =>
      'Saqlamasdan chiqish';

  @override
  String get editProfileAvatarUploadingToast =>
      'Iltimos, rasm yuklanib bo\'lguncha kuting.';

  @override
  String get editProfileUpdateSuccessToast =>
      'Profil muvaffaqiyatli yangilandi!';

  @override
  String editProfileUpdateErrorToast(String message) {
    return 'Profilni yangilashda xatolik: $message';
  }

  @override
  String get editProfileNetworkErrorMessage =>
      'Internet aloqasi yo\'q. Tarmog\'ingizni tekshirib, qaytadan urinib ko\'ring.';

  @override
  String get editProfileGenericErrorMessage => 'Nimadir xato ketdi';

  @override
  String get editProfileSignedOutMessage =>
      'Profilingizni tahrirlash uchun tizimga kiring.';

  @override
  String get editProfileSignedOutGoBackLabel => 'Orqaga qaytish';

  @override
  String get editProfileFullNameFieldLabel => 'To\'liq ism';

  @override
  String get editProfileFullNameRequiredError => 'Ism kiritilishi shart';

  @override
  String get editProfilePhoneFieldLabel => 'Telefon';

  @override
  String get editProfilePhoneInvalidError =>
      'O\'zbekiston telefon raqami noto\'g\'ri';

  @override
  String get editProfileEmailFieldLabel => 'Email';

  @override
  String get editProfileEmailRequiredError => 'Email kiritilishi shart';

  @override
  String get editProfilePasswordFieldLabel => 'Parol';

  @override
  String get editProfilePasswordHint =>
      'Joriy parolni saqlab qolish uchun bo\'sh qoldiring';

  @override
  String get editProfilePasswordLengthError =>
      'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';

  @override
  String get editProfileCancelButtonLabel => 'Bekor qilish';

  @override
  String get editProfileSaveButtonLabel => 'Saqlash';

  @override
  String get contactRequiredFieldsError => 'Majburiy maydonlar to\'ldirilmagan';

  @override
  String get contactInvalidPhoneError => 'Telefon raqami formati noto\'g\'ri';

  @override
  String get contactSendSuccessToast => 'Xabar muvaffaqiyatli yuborildi.';

  @override
  String get contactRateLimitedError =>
      'Hozircha juda ko\'p xabar yuborildi. Bir daqiqadan so\'ng qaytadan urinib ko\'ring.';

  @override
  String get contactUnconfiguredError =>
      'Aloqa shakli hozircha mavjud emas. Iltimos, rieltorga to\'g\'ridan-to\'g\'ri qo\'ng\'iroq qiling.';

  @override
  String get contactGenericErrorMessage =>
      'Xabaringizni hozircha yuborib bo\'lmadi. Qaytadan urinib ko\'ring.';

  @override
  String get contactNetworkErrorMessage =>
      'Internet aloqasi yo\'q. Tarmog\'ingizni tekshirib, qaytadan urinib ko\'ring.';

  @override
  String get contactSheetTitle => 'Biz bilan bog\'laning';

  @override
  String get contactSheetCloseLabel => 'Yopish';

  @override
  String get contactSheetSubtitle =>
      'Barcha fikr-mulohaza, muammo va takliflaringizni mamnuniyat bilan qabul qilamiz. Sizga qulay bo\'lgan istalgan vaqtda biz bilan bog\'lanishingiz mumkin.';

  @override
  String get contactFullNameFieldLabel => 'To\'liq ism';

  @override
  String get contactPhoneFieldLabel => 'Telefon';

  @override
  String get contactMessageFieldLabel => 'Xabar';

  @override
  String get contactSendButtonLabel => 'Xabar yuborish';

  @override
  String reviewsRatingInputStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yulduz',
    );
    return '$_temp0';
  }

  @override
  String get leadsListScreenTitle => 'Lidlar';

  @override
  String get leadsKanbanScreenTitle => 'Kanban';

  @override
  String get leadsToggleViewKanbanLabel => 'Kanban sifatida ko\'rish';

  @override
  String get leadsToggleViewListLabel => 'Ro\'yxat sifatida ko\'rish';

  @override
  String get leadsAddNewLeadLabel => 'Yangi lid qo\'shish';

  @override
  String get leadsEmptyMessage => 'Hozircha lidlar yo\'q.';

  @override
  String get leadsLoadErrorMessage => 'Lidlaringizni yuklab bo\'lmadi.';

  @override
  String get leadsEmptyColumnMessage => 'Bu bosqichda hozircha lidlar yo\'q.';

  @override
  String get leadsCardMoveFailedMessage =>
      'Ko\'chirib bo\'lmadi — qayta urinib ko\'ring.';

  @override
  String get leadsCreateScreenTitle => 'Lid yaratish';

  @override
  String get leadsFieldFullNameLabel => 'To\'liq ism';

  @override
  String get leadsFieldPhoneLabel => 'Telefon';

  @override
  String get leadsFieldEmailLabel => 'Email';

  @override
  String get leadsFieldBudgetLabel => 'Byudjet';

  @override
  String get leadsFieldCommitLabel => 'Izoh';

  @override
  String get leadsFieldSourceLabel => 'Manba';

  @override
  String get leadsCreateCommitHint => 'Bu lid nimani izlayapti?';

  @override
  String get leadsCreateFullNameRequiredError => 'Ism kiritilishi shart';

  @override
  String get leadsCreatePhoneRequiredError =>
      'Telefon raqami kiritilishi shart';

  @override
  String get leadsPhoneInvalidError =>
      'O\'zbekiston telefon raqami noto\'g\'ri';

  @override
  String get leadsDetailFullNameRequiredError =>
      'To\'liq ism kiritilishi shart';

  @override
  String get leadsBudgetInvalidError => 'To\'g\'ri raqam kiriting';

  @override
  String get leadsStatusFieldLabel => 'HOLAT';

  @override
  String get leadsCallTimeLabel => 'QO\'NG\'IROQ VAQTI';

  @override
  String get leadsSelectDateLabel => 'Sanani tanlang';

  @override
  String get leadsCoworkerFieldLabel => 'HAMKASB';

  @override
  String get leadsCoworkerUnavailableNote =>
      'Hamkasb tayinlash hozircha bu versiyada mavjud emas.';

  @override
  String get leadsCancelButtonLabel => 'Bekor qilish';

  @override
  String get leadsSaveButtonLabel => 'Saqlash';

  @override
  String get leadsCreatedToastMessage => 'Lid muvaffaqiyatli yaratildi!';

  @override
  String leadsCreateErrorToastMessage(String message) {
    return 'Lid yaratishda xatolik: $message';
  }

  @override
  String get leadsUpdatedToastMessage => 'Lid muvaffaqiyatli yangilandi!';

  @override
  String leadsUpdateErrorToastMessage(String message) {
    return 'Lidni yangilashda xatolik: $message';
  }

  @override
  String get leadsDeletedToastMessage => 'Lid muvaffaqiyatli o\'chirildi!';

  @override
  String leadsDeleteErrorToastMessage(String message) {
    return 'Lidni o\'chirishda xatolik: $message';
  }

  @override
  String get leadsNoConnectionMessage =>
      'Ulanish yo\'q. Tarmog\'ingizni tekshirib, qayta urinib ko\'ring.';

  @override
  String get leadsSubjectNoun => 'lid';

  @override
  String get leadsDetailCloseLabel => 'Yopish';

  @override
  String get leadsDetailLoadErrorMessage => 'Bu lidni yuklab bo\'lmadi.';

  @override
  String get leadsDeleteLeadButtonLabel => 'Lidni o\'chirish';

  @override
  String leadsCommitMinLengthError(int min) {
    return 'Kamida $min ta belgi.';
  }

  @override
  String get leadsCallbackSheetTitle => 'Keyingi qo\'ng\'iroq vaqtini kiriting';

  @override
  String get leadsConversationSheetTitle => 'Suhbat haqida qisqacha yozing';

  @override
  String get leadsConversationHint => 'Nima haqida gaplashdingiz?';

  @override
  String get leadsMoveToSheetTitle => 'Ko\'chirish…';

  @override
  String get coworkersListScreenTitle => 'Hamkasblar';

  @override
  String get coworkersLoadErrorMessage => 'Hamkasblaringizni yuklab bo\'lmadi';

  @override
  String get coworkersEmptyMessage => 'Hozircha hamkasblar yo\'q.';

  @override
  String get coworkersAddNewButtonLabel => '+ Yangi hamkasb qo\'shish';

  @override
  String coworkersListingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta e\'lon',
    );
    return '$_temp0';
  }

  @override
  String get coworkersCreateScreenTitle => 'Hamkasb yaratish';

  @override
  String get coworkersUploadWaitMessage => 'Rasm yuklanib bo\'lguncha kuting.';

  @override
  String get coworkersUploadingToastLabel => 'Yuklanmoqda';

  @override
  String get coworkersCreatedToastMessage => 'Hamkasb muvaffaqiyatli yaratildi';

  @override
  String coworkersCreateErrorToastMessage(String message) {
    return 'Hamkasb yaratishda xatolik: $message';
  }

  @override
  String get coworkersNoConnectionMessage =>
      'Ulanish yo\'q. Tarmog\'ingizni tekshirib, qayta urinib ko\'ring.';

  @override
  String get coworkersGenericErrorMessage => 'Nimadir xato ketdi';

  @override
  String get coworkersSignInPromptMessage =>
      'Jamoangizni boshqarish uchun tizimga kiring.';

  @override
  String get coworkersSignInActionLabel => 'Kirish';

  @override
  String get coworkersAgentOnlyMessage =>
      'Faqat rieltorlar hamkasb qo\'sha oladi.';

  @override
  String get coworkersGoBackLabel => 'Orqaga qaytish';

  @override
  String get coworkersSoloAgentMessage =>
      'Yakka rieltorlarning jamoasi yo\'q. Hamkasb qo\'shish uchun agentlik hisobiga o\'ting.';

  @override
  String get coworkersAddPhotoLabel => 'Rasm qo\'shish';

  @override
  String get coworkersChangePhotoLabel => 'Rasmni o\'zgartirish';

  @override
  String get coworkersFieldFullNameLabel => 'To\'liq ism';

  @override
  String get coworkersFieldPhoneLabel => 'Telefon';

  @override
  String get coworkersFieldEmailLabel => 'Email';

  @override
  String get coworkersFieldPasswordLabel => 'Parol';

  @override
  String get coworkersPasswordHint => 'Kamida 6 ta belgi';

  @override
  String get coworkersPasswordHintKeepCurrent =>
      'Joriy parolni saqlab qolish uchun bo\'sh qoldiring';

  @override
  String get coworkersFullNameRequiredError => 'To\'liq ism kiritilishi shart';

  @override
  String get coworkersPhoneRequiredError => 'Telefon raqami kiritilishi shart';

  @override
  String get coworkersPhoneInvalidError =>
      'O\'zbekiston telefon raqami noto\'g\'ri';

  @override
  String get coworkersEmailRequiredError => 'Email kiritilishi shart';

  @override
  String get coworkersPasswordRequiredError => 'Parol kiritilishi shart';

  @override
  String get coworkersPasswordTooShortError =>
      'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';

  @override
  String get coworkersCancelButtonLabel => 'Bekor qilish';

  @override
  String get coworkersSaveButtonLabel => 'Saqlash';

  @override
  String get coworkersDeleteButtonLabel => 'O\'chirish';

  @override
  String get coworkersSubjectNoun => 'hamkasb';

  @override
  String get coworkersDetailScreenTitle => 'Hamkasbni yangilash';

  @override
  String get coworkersNotFoundMessage => 'Bu hamkasb endi mavjud emas.';

  @override
  String get coworkersDetailLoadErrorMessage => 'Bu hamkasbni yuklab bo\'lmadi';

  @override
  String get coworkersUpdatedToastMessage =>
      'Hamkasb muvaffaqiyatli yangilandi!';

  @override
  String coworkersUpdateErrorToastMessage(String message) {
    return 'Hamkasbni yangilashda xatolik: $message';
  }

  @override
  String get coworkersDeletedToastMessage =>
      'Hamkasb muvaffaqiyatli o\'chirildi!';

  @override
  String coworkersDeleteErrorToastMessage(String message) {
    return 'Hamkasbni o\'chirishda xatolik: $message';
  }

  @override
  String get coworkersReadOnlyNoteMessage =>
      'Faqat rieltorlar hamkasblarni tahrirlashi yoki o\'chirishi mumkin.';

  @override
  String coworkersActivitySummaryLine(String listings, String active) {
    return '$listings · Faol: $active';
  }

  @override
  String get coworkersActivityJustNow => 'Hozirgina';

  @override
  String coworkersActivityMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daq. oldin',
    );
    return '$_temp0';
  }

  @override
  String coworkersActivityHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soat oldin',
    );
    return '$_temp0';
  }

  @override
  String get coworkersActivityYesterday => 'Kecha';

  @override
  String coworkersActivityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun oldin',
    );
    return '$_temp0';
  }

  @override
  String get dashboardScreenHeaderTitle => 'Statistika';

  @override
  String get dashboardNotificationsSemanticsLabel => 'Bildirishnomalar';

  @override
  String get dashboardCoworkerStatisticsSectionTitle =>
      'Hamkasblar statistikasi';

  @override
  String get dashboardWorkspaceGroupLabel => 'Ish maydoni';

  @override
  String get dashboardAdsStatisticsTitle => 'E\'lonlar statistikasi';

  @override
  String get dashboardAdsStatisticsLoadErrorMessage =>
      'E\'lonlar statistikasini yuklab bo\'lmadi';

  @override
  String get dashboardNoDataForRangeMessage => 'Bu davr uchun ma\'lumot yo\'q.';

  @override
  String get dashboardLegendCreated => 'Yaratilgan';

  @override
  String get dashboardLegendSold => 'Sotilgan';

  @override
  String dashboardCaptionHour(String hour) {
    return 'Soat $hour';
  }

  @override
  String dashboardCaptionHoursRange(String start, String end) {
    return 'Soatlar $start–$end';
  }

  @override
  String dashboardCaptionDay(int day) {
    return '$day-kun';
  }

  @override
  String dashboardCaptionDaysRange(int start, int end) {
    return '$start–$end-kunlar';
  }

  @override
  String get dashboardCoworkerStatisticsLoadErrorMessage =>
      'Hamkasblar statistikasini yuklab bo\'lmadi';

  @override
  String get dashboardNoCoworkersMessage => 'Hozircha hamkasblar yo\'q.';

  @override
  String get dashboardLegendAdsCount => 'E\'lonlar soni';

  @override
  String get dashboardLegendLeadCount => 'Lidlar soni';

  @override
  String get dashboardLegendSaleCount => 'Sotuvlar soni';

  @override
  String get dashboardHeaderCoworkers => 'HAMKASBLAR';

  @override
  String get dashboardHeaderAds => 'E\'LONLAR';

  @override
  String get dashboardHeaderLeads => 'LIDLAR';

  @override
  String get dashboardHeaderSales => 'SOTUVLAR';

  @override
  String get dashboardTileAdsCreatedLabel => 'Yaratilgan e\'lonlar';

  @override
  String get dashboardTileAdsSoldLabel => 'Sotilgan e\'lonlar';

  @override
  String get dashboardTileActiveLeadsLabel => 'Faol lidlar';

  @override
  String get dashboardTileCoworkersLabel => 'Hamkasblar';

  @override
  String get dashboardTileTapToManageSubtitle => 'boshqarish uchun bosing';

  @override
  String get dashboardRangeSubtitleAll => 'barcha vaqt';

  @override
  String get dashboardRangeSubtitleThisMonth => 'shu oy';

  @override
  String get dashboardRangeSubtitleThisWeek => 'shu hafta';

  @override
  String get dashboardRangeSubtitleToday => 'bugun';

  @override
  String dashboardCallbackSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taga qayta qo\'ng\'iroq kerak',
    );
    return '$_temp0';
  }

  @override
  String get dashboardFilterLabelAll => 'Hammasi';

  @override
  String get dashboardFilterLabelThisMonth => 'Shu oy';

  @override
  String get dashboardFilterLabelThisWeek => 'Shu hafta';

  @override
  String get dashboardFilterLabelToday => 'Bugun';

  @override
  String get dashboardWorkspaceMyAdsRowTitle => 'Mening e\'lonlarim';

  @override
  String get dashboardWorkspaceLeadsRowTitle => 'Lidlar';

  @override
  String get dashboardWorkspaceCoworkersRowTitle => 'Hamkasblar';

  @override
  String dashboardWorkspaceMyAdsSubtitle(int listings, int drafts) {
    return '$listings ta e\'lon · $drafts ta qoralama';
  }

  @override
  String dashboardWorkspaceLeadsSubtitle(int active, int dueToday) {
    return '$active ta faol · $dueToday taga qayta qo\'ng\'iroq kerak';
  }

  @override
  String dashboardWorkspaceCoworkersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kishi',
    );
    return '$_temp0';
  }

  @override
  String get notificationsScreenTitle => 'Bildirishnomalar';

  @override
  String get notificationsLoadErrorMessage =>
      'Bildirishnomalaringizni yuklab bo\'lmadi.';

  @override
  String get notificationsEmptyMessage => 'Hozircha bildirishnomalar yo\'q.';

  @override
  String notificationsUnreadSemanticsLabel(String title) {
    return '$title, o\'qilmagan';
  }

  @override
  String get notificationsRelativeJustNow => 'Hozirgina';

  @override
  String notificationsRelativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daq. oldin',
    );
    return '$_temp0';
  }

  @override
  String notificationsRelativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soat oldin',
    );
    return '$_temp0';
  }

  @override
  String get notificationsRelativeYesterday => 'Kecha';

  @override
  String notificationsRelativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun oldin',
    );
    return '$_temp0';
  }

  @override
  String get messagesScreenTitle => 'Xabarlar';

  @override
  String get messagesComingSoonBanner =>
      'Xabar yozish tez orada qo\'shiladi. Hozircha lidlar bilan telefon orqali bog\'laning.';

  @override
  String get connectedAccountsScreenTitle => 'Ulangan hisoblar';

  @override
  String get connectedAccountsInstagramToggleTitle => 'Instagram post yaratish';

  @override
  String get connectedAccountsTelegramToggleTitle => 'Telegram post yaratish';

  @override
  String get connectedAccountsYoutubeToggleTitle => 'Youtube post yaratish';

  @override
  String get connectedAccountsInstagramLoadErrorMessage =>
      'Instagram hisoblaringizni yuklab bo\'lmadi.';

  @override
  String get connectedAccountsAvatarFallbackName => 'Instagram';

  @override
  String get connectedAccountsDisconnectingToastLabel => 'Uzilmoqda';

  @override
  String get connectedAccountsDisconnectedToastMessage =>
      'Instagram hisobi uzildi.';

  @override
  String get connectedAccountsFallbackAccountName => 'Instagram hisobi';

  @override
  String connectedAccountsDisconnectSemanticsLabel(String name) {
    return '${name}ni uzish';
  }

  @override
  String get connectedAccountsDisconnectButtonLabel => 'Uzish';

  @override
  String connectedAccountsPostsStatLabel(int count) {
    return 'Postlar $count';
  }

  @override
  String connectedAccountsFollowersStatLabel(int count) {
    return 'Obunachilar $count';
  }

  @override
  String connectedAccountsFollowingStatLabel(int count) {
    return 'Obuna bo\'lganlar $count';
  }

  @override
  String get connectedAccountsConnectButtonLabel => 'Instagramni ulash';

  @override
  String get connectedAccountsOpeningBrowserToastMessage =>
      'Instagramga kirish brauzeringizda ochilmoqda.';

  @override
  String get connectedAccountsLinkCopiedToastMessage =>
      'Brauzerni ochib bo\'lmadi — Instagramga kirish havolasi nusxalandi. Ulanish uchun uni brauzeringizga joylashtiring.';

  @override
  String get connectedAccountsConnectionFailedToastMessage =>
      'Instagramga ulanib bo\'lmadi — qayta urinib ko\'ring.';

  @override
  String connectedAccountsTelegramChannelsConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta kanal ulangan',
    );
    return '$_temp0';
  }

  @override
  String get connectedAccountsTelegramNoChannelsMessage =>
      'Hech qanday Telegram kanali ulanmagan';

  @override
  String get connectedAccountsYoutubeAddAccountLabel => 'Hisob qo\'shish';

  @override
  String get connectedAccountsYoutubeSignOutLabel => 'Chiqish';

  @override
  String connectedAccountsUnavailableSemanticsSuffix(String label) {
    return '$label (bu versiyada mavjud emas)';
  }

  @override
  String get connectedAccountsYoutubeBetaNoteMessage =>
      'Beta — bu versiyada mavjud emas.';

  @override
  String get connectedAccountsConnectedStatusLabel => 'Ulangan';

  @override
  String get connectedAccountsNotConnectedStatusLabel => 'Ulanmagan';

  @override
  String get leadsCommitFieldUppercaseLabel => 'IZOH';

  @override
  String get languageSheetTitle => 'Til';

  @override
  String get languageSheetCloseLabel => 'Yopish';
}
