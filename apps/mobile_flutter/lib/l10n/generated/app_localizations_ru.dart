// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsScreenTitle => 'Настройки';

  @override
  String get settingsNavBackLabel => 'Назад';

  @override
  String get settingsLanguageRowTitle => 'Язык';

  @override
  String get settingsConnectedAccountsRowTitle => 'Подключённые аккаунты';

  @override
  String get settingsAboutRowTitle => 'О приложении';

  @override
  String settingsAboutRowSubtitle(String version) {
    return 'Версия $version';
  }

  @override
  String settingsAboutToastMessage(String appName, String version) {
    return '$appName $version';
  }

  @override
  String get settingsSessionGroupLabel => 'Сессия';

  @override
  String get settingsLogoutRowTitle => 'Выйти';

  @override
  String get settingsLoggingOutLabel => 'Выполняется выход…';

  @override
  String get settingsSignOutTokenNotClearedMessage =>
      'Вы вышли из аккаунта, но сохранённую сессию не удалось удалить с этого устройства. Прежде чем передавать устройство другому человеку, выйдите ещё раз или удалите приложение.';

  @override
  String get settingsNotificationsRowTitle => 'Уведомления';

  @override
  String get settingsNotificationsRowSubtitle =>
      'Пока не отправляются — push-уведомления не подключены в этой версии приложения.';

  @override
  String get settingsNotificationsToggleLabel => 'Переключатель уведомлений';

  @override
  String get homeLocationPillLabel => 'Ташкент, Узбекистан';

  @override
  String homeNotificationsBellSemanticLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Непрочитанных уведомлений: $count',
      many: 'Непрочитанных уведомлений: $count',
      few: 'Непрочитанных уведомления: $count',
      one: 'Непрочитанное уведомление: $count',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchIconSemanticLabel => 'Поиск';

  @override
  String get homeAgentPitchHeading => 'Вы риелтор?';

  @override
  String get homeAgentPitchSubtitle =>
      'Управляйте объявлениями, лидами и командой в одном приложении.';

  @override
  String get homeAgentPitchButtonLabel => 'Начать';

  @override
  String get homeCategoryAllLabel => 'Все';

  @override
  String get homeCategoryApartmentLabel => 'Квартира';

  @override
  String get homeCategoryHouseLabel => 'Дом';

  @override
  String get homeCategoryOfficeLabel => 'Офис';

  @override
  String get homeCategoryRetailLabel => 'Торговое помещение';

  @override
  String homeCategoryChipSemanticsLabel(String category) {
    return 'Показать объявления: $category';
  }

  @override
  String get homeExploreNearbySectionTitle => 'Рядом с вами';

  @override
  String get homeFeaturedListingsSectionTitle => 'Рекомендуемые объявления';

  @override
  String get homeFeaturedListingsViewAllLabel => 'Смотреть все';

  @override
  String get homeFeaturedListingsRetryMessage =>
      'Не удалось загрузить объявления';

  @override
  String get homeFeedEmptyMessage => 'Пока нет доступных объявлений.';

  @override
  String get homeFeedCategoryEmptyMessage =>
      'В этой категории пока нет объявлений.';

  @override
  String get homePromoOneTitle => 'Один пост —\nна всех каналах';

  @override
  String get homePromoOneSubtitle => 'Instagram, Telegram и YouTube';

  @override
  String get homePromoTwoTitle => 'Новинка\nв Яшнабаде';

  @override
  String get homePromoTwoSubtitle => '4-комнатные новостройки от \$95 000';

  @override
  String get homeTopAgentsSectionTitle => 'Лучшие риелторы';

  @override
  String get homeTopAgentsExploreLinkLabel => 'Смотреть';

  @override
  String get homeTopAgentsRetryMessage => 'Не удалось загрузить риелторов';

  @override
  String homeAgentAdsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count объявлений',
      many: '$count объявлений',
      few: '$count объявления',
      one: '$count объявление',
    );
    return '$_temp0';
  }

  @override
  String homeAgentRatingCaption(String rating, int count) {
    return '★ $rating ($count)';
  }

  @override
  String get homeTopDistrictsSectionTitle => 'Популярные районы';

  @override
  String get homeTopDistrictsExploreLinkLabel => 'Смотреть';

  @override
  String homeDistrictListingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count объявлений',
      many: '$count объявлений',
      few: '$count объявления',
      one: '$count объявление',
    );
    return '$_temp0';
  }

  @override
  String homeDistrictTapSemanticsLabel(String district) {
    return 'Показать объявления в районе $district';
  }

  @override
  String get searchScreenTitle => 'Поиск';

  @override
  String get searchInputHint => 'Поиск по городу, району или названию';

  @override
  String get searchCancelButtonLabel => 'Отмена';

  @override
  String get searchFiltersButtonLabel => 'Фильтры';

  @override
  String get searchSortHighestPriceLabel => 'Сначала дорогие';

  @override
  String get searchSortLowestPriceLabel => 'Сначала дешёвые';

  @override
  String get searchSortNewestLabel => 'Сначала новые';

  @override
  String get searchResultsRetryMessage => 'Не удалось загрузить объявления.';

  @override
  String get searchResultsEmptyMessage =>
      'По вашему запросу объявления не найдены.';

  @override
  String get searchResultsFilteredEmptyMessage =>
      'Нет объявлений, соответствующих фильтрам.';

  @override
  String get searchRecentSearchesSectionTitle => 'Недавние поиски';

  @override
  String get searchRecentSearchesClearLabel => 'Очистить';

  @override
  String get filterSheetTitle => 'Фильтры';

  @override
  String get filterSheetCloseLabel => 'Закрыть';

  @override
  String get filterCountErrorMessage =>
      'Не удалось подсчитать подходящие объявления.';

  @override
  String get filterApplyButtonLabel => 'Применить фильтры';

  @override
  String filterApplyButtonWithCountLabel(int count) {
    return 'Применить фильтры ($count)';
  }

  @override
  String get filterResetButtonLabel => 'Сбросить';

  @override
  String get filterAreaMinFieldLabel => 'Мин. общая площадь';

  @override
  String get filterAreaMaxFieldLabel => 'Макс. общая площадь';

  @override
  String get filterCategoryFieldLabel => 'Категория';

  @override
  String get filterTypeFieldLabel => 'Тип';

  @override
  String get filterCategoryRentOptionLabel => 'Аренда';

  @override
  String get filterCategorySaleOptionLabel => 'Продажа';

  @override
  String get filterTypeResidentialOptionLabel => 'Жилая';

  @override
  String get filterTypeNonresidentialOptionLabel => 'Нежилая';

  @override
  String get filterCityFieldLabel => 'Город';

  @override
  String get filterCityPickerTitle => 'Город';

  @override
  String get filterCityAnyOptionLabel => 'Любой город';

  @override
  String get filterDistrictFieldLabel => 'Район';

  @override
  String get filterDistrictPickerTitle => 'Район';

  @override
  String get filterDistrictAnyOptionLabel => 'Любой район';

  @override
  String get filterDistrictPickCityFirstPlaceholder => 'Сначала выберите город';

  @override
  String get filterRegionsLoadingPlaceholder => 'Загрузка…';

  @override
  String get filterRegionsErrorPlaceholder => 'Не удалось загрузить';

  @override
  String get filterFurnitureFieldLabel => 'Мебель';

  @override
  String get filterRepairFieldLabel => 'Ремонт';

  @override
  String get filterFurnitureWithOptionLabel => 'С мебелью';

  @override
  String get filterFurnitureWithoutOptionLabel => 'Без мебели';

  @override
  String get filterRepairNotRepairedOptionLabel => 'Без ремонта';

  @override
  String get filterRepairNormalOptionLabel => 'Обычный';

  @override
  String get filterRepairGoodOptionLabel => 'Хороший';

  @override
  String get filterRepairExcellentOptionLabel => 'Отличный';

  @override
  String get filterPriceMinFieldLabel => 'Мин. цена';

  @override
  String get filterPriceMaxFieldLabel => 'Макс. цена';

  @override
  String get filterRoomsFieldLabel => 'Комнаты';

  @override
  String get filterSortFieldLabel => 'Сортировка';

  @override
  String get filterStatusFieldLabel => 'Статус';

  @override
  String get filterSortNewestOptionLabel => 'Сначала новые';

  @override
  String get filterSortHighestPriceOptionLabel => 'Сначала дорогие';

  @override
  String get filterSortLowestPriceOptionLabel => 'Сначала дешёвые';

  @override
  String get filterStatusActiveOptionLabel => 'Активный';

  @override
  String get filterStatusSoldOptionLabel => 'Продано';

  @override
  String get filterStatusDraftOptionLabel => 'Черновик';

  @override
  String get filterStoreyFieldLabel => 'Этаж';

  @override
  String get listingOverviewSectionTitle => 'Обзор';

  @override
  String get listingDescriptionSectionTitle => 'Описание';

  @override
  String get listingAdditionalInfoSectionTitle => 'Дополнительная информация';

  @override
  String get listingSizesSectionTitle => 'Размеры';

  @override
  String get listingNearbyPlacesSectionTitle => 'Ближайшие места';

  @override
  String get listingLocationSectionTitle => 'Расположение';

  @override
  String get listingNotFoundMessage =>
      'Это объявление больше недоступно.\nВозможно, оно было продано или удалено.';

  @override
  String get listingLoadErrorMessage => 'Не удалось загрузить это объявление.';

  @override
  String get listingAgentUnavailableLabel => 'Данные риелтора недоступны';

  @override
  String listingAgentStatsLine(int adsCount, int dealsClosedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      adsCount,
      locale: localeName,
      other: 'Риелтор · $adsCount объявления · $dealsClosedCount закрыто',
      many: 'Риелтор · $adsCount объявлений · $dealsClosedCount закрыто',
      few: 'Риелтор · $adsCount объявления · $dealsClosedCount закрыто',
      one: 'Риелтор · $adsCount объявление · $dealsClosedCount закрыто',
    );
    return '$_temp0';
  }

  @override
  String listingAgentCallSemanticsLabel(String fullName) {
    return 'Позвонить: $fullName';
  }

  @override
  String get listingSubmitApplicationButtonLabel => 'Отправить заявку';

  @override
  String get listingFavouriteUpdateErrorMessage =>
      'Не удалось обновить избранное';

  @override
  String get listingSaveThePlaceButtonLabel => 'Сохранить объект';

  @override
  String get listingSavedButtonLabel => 'Сохранено';

  @override
  String get listingNavBackSemanticsLabel => 'Назад';

  @override
  String get listingNavShareSemanticsLabel => 'Поделиться';

  @override
  String get listingHeroVideoBadgeLabel => 'Видео';

  @override
  String get listingLinkCopiedToastMessage => 'Ссылка скопирована для отправки';

  @override
  String get listingNoLocationMessage =>
      'Для этого объявления не указано местоположение.';

  @override
  String get listingAskingPriceLabel => 'Запрашиваемая цена';

  @override
  String get listingSizesAreaLabel => 'Площадь';

  @override
  String get listingSizesRoomsLabel => 'Комнаты';

  @override
  String get listingSizesFloorLabel => 'Этаж';

  @override
  String get listingSizesTypeLabel => 'Тип';

  @override
  String get listingTourSectionTitle => '3D-тур';

  @override
  String get listingTourViewSemanticsLabel => 'Смотреть 3D-тур';

  @override
  String get listingTourBannerLabel => 'Живой 3D-тур';

  @override
  String get listingTourInvalidLinkMessage =>
      'Ссылка на 3D-тур этого объявления недействительна.';

  @override
  String get listingTourLoadErrorMessage => 'Не удалось загрузить 3D-тур.';

  @override
  String get listingTypeResidentialLabel => 'Жилая';

  @override
  String get listingTypeNonresidentialLabel => 'Нежилая';

  @override
  String get listingCategorySaleLabel => 'Продажа';

  @override
  String get listingCategoryRentLabel => 'Аренда';

  @override
  String get listingRepairmentNotRepairedLabel => 'Без ремонта';

  @override
  String get listingRepairmentNormalLabel => 'Обычный';

  @override
  String get listingRepairmentGoodLabel => 'Хороший';

  @override
  String get listingRepairmentExcellentLabel => 'Отличный';

  @override
  String get listingFurnitureWithLabel => 'С мебелью';

  @override
  String get listingFurnitureWithoutLabel => 'Без мебели';

  @override
  String listingRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комнаты',
      many: '$count комнат',
      few: '$count комнаты',
      one: '$count комната',
    );
    return '$_temp0';
  }

  @override
  String get galleryEmptyStateMessage =>
      'Для этого объявления нет доступных фотографий.';

  @override
  String get galleryVideoUnsupportedMessage =>
      'Предпросмотр видео пока недоступен в галерее.';

  @override
  String get galleryUnsupportedMediaMessage =>
      'Этот тип файла нельзя предпросмотреть.';

  @override
  String get galleryOpenVideoExternallyLabel => 'Открыть видео';

  @override
  String get galleryVideoLinkCopiedToastMessage =>
      'Не удалось открыть видео — ссылка скопирована. Вставьте её в браузер, чтобы посмотреть.';

  @override
  String galleryPositionSemanticsLabel(int current, int total) {
    return 'Позиция в галерее: $current из $total';
  }

  @override
  String galleryThumbnailSemanticsLabel(int index, int total) {
    return 'Фото $index из $total';
  }

  @override
  String get galleryCloseTooltip => 'Закрыть галерею';

  @override
  String galleryCounterSemanticsLabel(String label) {
    return 'Фото $label';
  }

  @override
  String get mapNavBackSemanticsLabel => 'Назад';

  @override
  String get mapTitleLabel => 'Карта';

  @override
  String get mapShowListSemanticsLabel => 'Показать список';

  @override
  String mapPinnedPartialCountLabel(int pinned, int total) {
    return '$pinned из $total на карте';
  }

  @override
  String mapPartialResultsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показаны первые $count объявлений',
      many: 'Показаны первые $count объявлений',
      few: 'Показаны первые $count объявления',
      one: 'Показано первое $count объявление',
    );
    return '$_temp0';
  }

  @override
  String get mapUpdatingResultsLabel => 'Обновляем…';

  @override
  String get mapFiltersButtonLabel => 'Фильтры';

  @override
  String get mapNoLocationResultsMessage =>
      'Ни для одного из этих объявлений не указано местоположение.';

  @override
  String get mapNoResultsMessage => 'По вашему запросу объявления не найдены.';

  @override
  String mapClusterSemanticsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Здесь $count объявления, нажмите, чтобы приблизить',
      many: 'Здесь $count объявлений, нажмите, чтобы приблизить',
      few: 'Здесь $count объявления, нажмите, чтобы приблизить',
      one: 'Здесь $count объявление, нажмите, чтобы приблизить',
    );
    return '$_temp0';
  }

  @override
  String mapPinSemanticsLabel(String title, String price) {
    return '$title, $price';
  }

  @override
  String get savedListingsNavBackSemanticsLabel => 'Назад';

  @override
  String get savedListingsScreenTitle => 'Сохранённые объявления';

  @override
  String get savedListingsSignInPromptMessage =>
      'Войдите, чтобы увидеть свои сохранённые объявления.';

  @override
  String get savedListingsSignInButtonLabel => 'Войти';

  @override
  String get savedListingsLoadErrorMessage =>
      'Не удалось загрузить сохранённые объявления';

  @override
  String get savedListingsEmptyStateMessage =>
      'Вы ещё не сохранили ни одного объявления.';

  @override
  String get sharedConfirmDialogCancelLabel => 'Отмена';

  @override
  String sharedDeleteConfirmTitle(String subject) {
    return 'Удалить $subject?';
  }

  @override
  String get sharedDeleteConfirmBody => 'Это действие нельзя отменить.';

  @override
  String get sharedDeleteConfirmDeleteLabel => 'Удалить';

  @override
  String get sharedDiscardChangesTitle => 'Отменить изменения?';

  @override
  String get sharedDiscardChangesBody =>
      'У вас есть несохранённые изменения. Если вы уйдёте сейчас, они не сохранятся.';

  @override
  String get sharedDiscardChangesDiscardLabel => 'Не сохранять';

  @override
  String get sharedSignOutTitle => 'Выйти из аккаунта?';

  @override
  String get sharedSignOutBody =>
      'Чтобы снова получить доступ к аккаунту, вам нужно будет войти заново.';

  @override
  String get sharedSignOutConfirmLabel => 'Выйти';

  @override
  String get sharedNoReviewsYetLabel => 'Пока нет отзывов';

  @override
  String sharedRatingLabel(String rating) {
    return 'Отзыв: $rating/5';
  }

  @override
  String get sharedStatusUnknownLabel => 'Неизвестно';

  @override
  String get sharedAdStageActiveLabel => 'Активный';

  @override
  String get sharedAdStageSoldLabel => 'Продано';

  @override
  String get sharedAdStageDraftLabel => 'Черновик';

  @override
  String get sharedLeadStatusNewLabel => 'Новый';

  @override
  String get sharedLeadStatusCouldNotConnectLabel => 'Не удалось связаться';

  @override
  String get sharedLeadStatusNeedToCallBackLabel => 'Нужно перезвонить';

  @override
  String get sharedLeadStatusRejectedLabel => 'Отклонён';

  @override
  String get sharedLeadStatusAcceptedLabel => 'Принят';

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
  String get sharedGenericErrorMessage => 'Что-то пошло не так.';

  @override
  String get sharedOfflineErrorMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get sharedShowPasswordLabel => 'Показать пароль';

  @override
  String get sharedHidePasswordLabel => 'Скрыть пароль';

  @override
  String get sharedChangePhotoLabel => 'Изменить фото';

  @override
  String get sharedMediaSourceCloseLabel => 'Закрыть';

  @override
  String get sharedMediaSourceCameraLabel => 'Камера';

  @override
  String get sharedMediaSourceGalleryLabel => 'Выбрать из галереи';

  @override
  String get sharedNavRowBackLabel => 'Назад';

  @override
  String get sharedNavRowCloseLabel => 'Закрыть';

  @override
  String sharedDialFallbackToastMessage(String phone) {
    return 'Не удалось открыть набор номера — номер телефона скопирован: $phone';
  }

  @override
  String get sharedFavouriteUpdateFailedMessage =>
      'Не удалось обновить избранное';

  @override
  String get sharedFavouriteAddSemanticsLabel => 'Добавить в избранное';

  @override
  String get sharedFavouriteRemoveSemanticsLabel => 'Удалить из избранного';

  @override
  String get sharedSignInToSaveMessage => 'Войдите, чтобы сохранять объявления';

  @override
  String get sharedSignInActionLabel => 'Войти';

  @override
  String get sharedClearFiltersActionLabel => 'Сбросить фильтры';

  @override
  String get sharedLoadMoreFailedLabel =>
      'Не удалось загрузить ещё — Повторить';

  @override
  String get sharedLoadMoreLabel => 'Показать ещё';

  @override
  String get sharedRetryLabel => 'Повторить';

  @override
  String get sharedListingCardSaleBadgeLabel => 'Продажа';

  @override
  String get sharedListingCardRentBadgeLabel => 'Аренда';

  @override
  String sharedRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count комнаты',
      many: '$count комнат',
      few: '$count комнаты',
      one: '$count комната',
    );
    return '$_temp0';
  }

  @override
  String get sharedPricePerMonthSuffix => '/мес';

  @override
  String get navTabHomeLabel => 'Главная';

  @override
  String get navTabSearchLabel => 'Поиск';

  @override
  String get navTabWorkLabel => 'Работа';

  @override
  String get navTabDashboardLabel => 'Статистика';

  @override
  String get navTabMyAdsLabel => 'Объявления';

  @override
  String get navTabLeadsLabel => 'Лиды';

  @override
  String get navTabCoworkersLabel => 'Коллеги';

  @override
  String get navTabAgentsLabel => 'Риелторы';

  @override
  String get navTabProfileLabel => 'Профиль';

  @override
  String get permissionsHeaderTitle => 'Разрешите La Casa…';

  @override
  String get permissionsCameraRowTitle => 'Камера и фото';

  @override
  String get permissionsCameraRowBody =>
      'Чтобы добавлять фото к объявлениям и аватару профиля';

  @override
  String get permissionsNotificationsRowTitle => 'Уведомления';

  @override
  String get permissionsNotificationsRowBody =>
      'Чтобы уведомлять вас о новых лидах и статусе публикации.';

  @override
  String get permissionsNotNowButtonLabel => 'Не сейчас';

  @override
  String get permissionsContinueButtonLabel => 'Продолжить';

  @override
  String get permissionsAllowButtonLabel => 'Разрешить';

  @override
  String get permissionsAllowedStatusLabel => 'Разрешено';

  @override
  String get permissionsLimitedStatusLabel =>
      'Разрешено — доступ ограничен выбранными фото. Нажмите, чтобы выбрать больше.';

  @override
  String get permissionsDeniedStatusLabel =>
      'Не разрешено — вы можете изменить это в настройках системы';

  @override
  String get permissionsPermanentlyDeniedStatusLabel =>
      'Не разрешено — нажмите, чтобы открыть настройки системы';

  @override
  String get permissionsUnavailableStatusLabel =>
      'Пока недоступно в этой версии';

  @override
  String get onboardingSkipButtonLabel => 'Пропустить';

  @override
  String get onboardingNextButtonLabel => 'Далее';

  @override
  String get onboardingGetStartedButtonLabel => 'Начать';

  @override
  String get onboardingSlideOneTitle =>
      'Управляйте всеми объявлениями в одном месте';

  @override
  String get onboardingSlideOneBody =>
      'Держите все объявления упорядоченными и легкодоступными — всё в одном приложении.';

  @override
  String get onboardingSlideTwoTitle => 'Публикуйте сразу во все каналы';

  @override
  String get onboardingSlideTwoBody =>
      'Публикуйте в Instagram, Telegram и другие каналы, не выходя из приложения.';

  @override
  String get onboardingSlideThreeTitle =>
      'Отслеживайте лидов от первого контакта до закрытия сделки';

  @override
  String get onboardingSlideThreeBody =>
      'Сортируйте и отслеживайте каждый запрос, чтобы ничего не упустить.';

  @override
  String get listingEditorCreateNavTitle => 'Добавить новое объявление';

  @override
  String get listingEditorEditNavTitle => 'Обновить объявление';

  @override
  String get listingEditorPublishStatusNavTitle => 'Статус публикации';

  @override
  String get listingEditorWizardBackLabel => 'Назад';

  @override
  String get listingEditorWizardNextLabel => 'Далее';

  @override
  String get listingEditorWizardCreateLabel => 'Создать';

  @override
  String get listingEditorWizardDisabledReasonMessage =>
      'Заполните обязательные поля, чтобы продолжить.';

  @override
  String get listingEditorStepBasicsLabel => 'Основное';

  @override
  String get listingEditorStepDetailsLabel => 'Детали';

  @override
  String get listingEditorStepPhotosLabel => 'Фото';

  @override
  String get listingEditorStepPublishLabel => 'Публикация';

  @override
  String listingEditorStepGoToSemanticsLabel(String step) {
    return 'Перейти к шагу «$step»';
  }

  @override
  String get listingEditorCreatePublishNoticeMessage =>
      'Публикация станет доступна после создания этого объявления — нажмите «Создать», а затем используйте кнопки для каждого канала на экране редактирования объявления.';

  @override
  String get listingEditorSummaryCardTitle => 'Сводка';

  @override
  String listingEditorSummaryPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото',
      many: '$count фото',
      few: '$count фото',
      one: '$count фото',
    );
    return '$_temp0';
  }

  @override
  String get listingEditorSummaryNotSetLabel => 'Не указано';

  @override
  String get listingEditorPendingUploadsMessage =>
      'Дождитесь завершения загрузки фото/видео.';

  @override
  String get listingEditorFailedUploadsMessage =>
      'Некоторые фото/видео не загрузились. Удалите их и добавьте заново перед сохранением.';

  @override
  String get listingEditorCreatePendingLabel => 'Создание';

  @override
  String get listingEditorCreateSuccessMessage => 'Успешно создано';

  @override
  String get listingEditorUpdatePendingLabel => 'Обновление';

  @override
  String get listingEditorUpdateSuccessMessage => 'Успешно обновлено';

  @override
  String get listingEditorDeletePendingLabel => 'Удаление';

  @override
  String get listingEditorDeleteSuccessMessage => 'Объявление удалено';

  @override
  String get listingEditorGenericErrorMessage => 'Что-то пошло не так.';

  @override
  String get listingEditorNetworkErrorMessage =>
      'Нет соединения. Проверьте сеть и повторите попытку.';

  @override
  String get listingEditorLoadErrorMessage =>
      'Не удалось загрузить это объявление.';

  @override
  String get listingEditorDeleteConfirmSubject => 'объявление';

  @override
  String get listingEditorTitleFieldLabel => 'Заголовок';

  @override
  String get listingEditorCityFieldLabel => 'Город';

  @override
  String get listingEditorDistrictFieldLabel => 'Район';

  @override
  String get listingEditorDistrictDisabledHint => 'Сначала выберите город';

  @override
  String get listingEditorAddressFieldLabel => 'Адрес';

  @override
  String get listingEditorReferenceFieldLabel => 'Ориентир';

  @override
  String get listingEditorReferenceHint => 'Ориентир / достопримечательность';

  @override
  String get listingEditorTypeFieldLabel => 'Тип';

  @override
  String get listingEditorCategoryFieldLabel => 'Категория';

  @override
  String get listingEditorRepairFieldLabel => 'Ремонт';

  @override
  String get listingEditorFurnitureFieldLabel => 'Мебель';

  @override
  String get listingEditorPriceTypeFieldLabel => 'Тип валюты';

  @override
  String get listingEditorStatusFieldLabel => 'Статус';

  @override
  String get listingEditorRoomsFieldLabel => 'Комнаты';

  @override
  String get listingEditorAreaFieldLabel => 'Площадь';

  @override
  String get listingEditorAreaUnitSuffix => 'м²';

  @override
  String get listingEditorStoreyFieldLabel => 'Этаж';

  @override
  String get listingEditorFloorsFieldLabel => 'Этажность';

  @override
  String get listingEditorHashtagsFieldLabel => 'Хэштеги';

  @override
  String get listingEditorHashtagsHint => '#new #2024';

  @override
  String get listingEditorPriceFieldLabel => 'Цена';

  @override
  String get listingEditorDescriptionFieldLabel => 'Описание';

  @override
  String get listingEditorTypeResidentialOption => 'Жилая';

  @override
  String get listingEditorTypeNonresidentialOption => 'Нежилая';

  @override
  String get listingEditorCategoryRentOption => 'Аренда';

  @override
  String get listingEditorCategorySaleOption => 'Продажа';

  @override
  String get listingEditorRepairNotRepairedOption => 'Без ремонта';

  @override
  String get listingEditorRepairNormalOption => 'Обычный';

  @override
  String get listingEditorRepairGoodOption => 'Хороший';

  @override
  String get listingEditorRepairExcellentOption => 'Отличный';

  @override
  String get listingEditorFurnitureWithOption => 'С мебелью';

  @override
  String get listingEditorFurnitureWithoutOption => 'Без мебели';

  @override
  String get listingEditorPriceTypeUzsOption => 'сум';

  @override
  String get listingEditorPriceTypeUsdOption => 'у.е.';

  @override
  String get listingEditorStageActiveOption => 'Активно';

  @override
  String get listingEditorStageSoldOption => 'Продано';

  @override
  String get listingEditorStageDraftOption => 'Черновик';

  @override
  String get listingEditorPricePreviewPlaceholder =>
      'Введите цену, чтобы увидеть предпросмотр.';

  @override
  String listingEditorPricePreviewText(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get listingEditorNearbyPlacesLabel => 'Ближайшие объекты';

  @override
  String get listingEditorNearbyPlacesHint =>
      'например, станция метро Чиланзар (7 минут пешком)';

  @override
  String get listingEditorNearbyPlacesAddButtonLabel => 'Добавить';

  @override
  String get listingEditorAdditionalInfoLabel => 'Дополнительная информация';

  @override
  String get listingEditorAdditionalInfoAddButtonLabel => 'Добавить';

  @override
  String get listingEditorAdditionalInfoKeyHint => 'Ключ';

  @override
  String get listingEditorAdditionalInfoValueHint => 'Значение';

  @override
  String get listingEditorNoExistingPhotosMessage =>
      'На этом объявлении пока нет фото.';

  @override
  String get listingEditorExistingPhotosLabel => 'Существующие фото';

  @override
  String get listingEditorAddPhotosLabel => 'Добавить фото';

  @override
  String get listingEditorAddPhotosButtonLabel => 'Добавить фото';

  @override
  String get listingEditorAddVideoButtonLabel => 'Добавить видео';

  @override
  String get listingEditorAddVideoOptionalHint => 'По желанию · до 70 МБ';

  @override
  String get listingEditorMediaLimitsHint =>
      'До 5 изображений (по 5 МБ каждое). Одно видео по желанию, до 70 МБ.';

  @override
  String get listingEditorAddPhotoSheetTitle => 'Добавить фото';

  @override
  String get listingEditorAddVideoSheetTitle => 'Добавить видео';

  @override
  String get listingEditorVideoFallbackFileName => 'Видео';

  @override
  String get listingEditorUploadFailedFallbackMessage =>
      'Не удалось загрузить. Попробуйте снова.';

  @override
  String get listingEditorUploadedStatusLabel => 'Загружено';

  @override
  String listingEditorUploadingProgressLabel(int percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String get listingEditorRetryUploadLabel => 'Повторить загрузку';

  @override
  String get listingEditorPublishSectionLabel => 'Публикация';

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
  String get listingEditorChannelUnknownLabel => 'Неизвестный канал';

  @override
  String get listingEditorYoutubeUnavailableHint =>
      'Бета — недоступно в этой сборке.';

  @override
  String get listingEditorOlxUnavailableHint =>
      'Кросс-постинг на OLX доступен только в десктопном приложении (требуется расширение браузера).';

  @override
  String get listingEditorThreadsUnavailableHint =>
      'Публикация в Threads требует профиля Threads, привязанного к профессиональному аккаунту Instagram, — эта сборка такой доступ не запрашивает.';

  @override
  String get listingEditorFacebookMarketplaceUnavailableHint =>
      'У Facebook Marketplace нет разрешённого способа автоматизации ни на одной платформе — объявления туда размещаются вручную.';

  @override
  String get listingEditorXUnavailableHint =>
      'Публикация в X требует отдельного приложения X API с платным тарифом на запись — ни того, ни другого в этой сборке нет.';

  @override
  String get listingEditorLinkedinUnavailableHint =>
      'Публикация в LinkedIn требует одобренного приложения LinkedIn Marketing API — в этой сборке нет учётных данных LinkedIn.';

  @override
  String get listingEditorPublishStatusLinkLabel => 'Статус публикации';

  @override
  String get listingEditorPublishChannelsSheetTitle =>
      'Выберите каналы, в которых хотите опубликовать!';

  @override
  String get listingEditorInstagramLoadErrorMessage =>
      'Не удалось загрузить подключённые аккаунты Instagram.';

  @override
  String listingEditorInstagramFollowersSubtitle(String count) {
    return 'Instagram · $count подписчиков';
  }

  @override
  String get listingEditorNoInstagramAccountMessage =>
      'Аккаунт Instagram не подключён. Вы можете подключить его в настройках или подготовить публикацию самостоятельно.';

  @override
  String get listingEditorNoTelegramChannelMessage =>
      'Канал Telegram не подключён.';

  @override
  String listingEditorTelegramChannelRowLabel(int chatId) {
    return 'Канал Telegram №$chatId';
  }

  @override
  String get listingEditorCancelButtonLabel => 'Отмена';

  @override
  String get listingEditorPublishButtonLabel => 'Опубликовать';

  @override
  String listingEditorInstagramPublishFailedMessage(String usernames) {
    return 'Публикация в Instagram не удалась для $usernames';
  }

  @override
  String get listingEditorInstagramPublishSuccessMessage =>
      'Публикация в Instagram размещена!';

  @override
  String listingEditorTelegramPublishFailedMessage(String chatIds) {
    return 'Публикация в Telegram не удалась для $chatIds';
  }

  @override
  String get listingEditorTelegramPublishSuccessMessage =>
      'Публикация в Telegram размещена!';

  @override
  String get listingEditorPublishStatusLoadErrorMessage =>
      'Не удалось загрузить статус публикации.';

  @override
  String get listingEditorOlxNotAvailableLabel => 'Недоступно на мобильном';

  @override
  String listingEditorLastAttemptLabel(String date) {
    return 'Последняя попытка: $date';
  }

  @override
  String get listingEditorViewPostLinkLabel => 'Посмотреть публикацию';

  @override
  String get listingEditorPostLinkCopiedMessage =>
      'Ссылка на публикацию скопирована в буфер обмена.';

  @override
  String get listingEditorYoutubeNonRetryableReason =>
      'У YouTube нет серверного вызова публикации для повтора — загрузка выполняется браузером в рамках вашей собственной сессии Google. Загрузите заново и сообщите результат.';

  @override
  String get listingEditorOlxNonRetryableReason =>
      'Публикация на OLX выполняется через расширение браузера, где человек проверяет и нажимает «Опубликовать». Повторите кросс-постинг из расширения.';

  @override
  String get listingEditorUnknownChannelReason =>
      'Неизвестный канал публикации.';

  @override
  String listingEditorRetrySuccessMessage(String channel) {
    return 'Повторная публикация в $channel выполнена успешно.';
  }

  @override
  String get listingEditorSaveButtonLabel => 'Сохранить';

  @override
  String get listingEditorDeleteButtonLabel => 'Удалить';

  @override
  String get listingEditorTitleRequiredError => 'Заголовок обязателен';

  @override
  String get listingEditorCityRequiredError => 'Город обязателен';

  @override
  String get listingEditorDistrictRequiredError => 'Район обязателен';

  @override
  String get listingEditorAddressRequiredError => 'Адрес обязателен';

  @override
  String get listingEditorReferenceRequiredError => 'Ориентир обязателен';

  @override
  String get listingEditorDescriptionRequiredError => 'Описание обязательно';

  @override
  String get myListingsNavTitle => 'Мои объявления';

  @override
  String get myListingsFilterButtonLabel => 'Фильтр';

  @override
  String get myListingsCreateButtonSemanticsLabel => 'Создать новое объявление';

  @override
  String get myListingsLoadErrorMessage =>
      'Не удалось загрузить ваши объявления.';

  @override
  String get myListingsEmptyStateMessage => 'Объявления не найдены.';

  @override
  String get myListingsFilteredEmptyStateMessage =>
      'Нет объявлений, соответствующих фильтрам.';

  @override
  String get myListingsEmptyStateActionLabel => 'Создать новое объявление';

  @override
  String get myListingsEditButtonSemanticsLabel => 'Редактировать';

  @override
  String get myListingsStageAllLabel => 'Все';

  @override
  String myListingsStageCountActiveLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активных',
      many: '$count активных',
      few: '$count активных',
      one: '$count активное',
    );
    return '$_temp0';
  }

  @override
  String myListingsStageCountSoldLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count проданных',
      many: '$count проданных',
      few: '$count проданных',
      one: '$count проданное',
    );
    return '$_temp0';
  }

  @override
  String myListingsStageCountDraftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count черновиков',
      many: '$count черновиков',
      few: '$count черновика',
      one: '$count черновик',
    );
    return '$_temp0';
  }

  @override
  String myListingsStageFilterSemanticsLabel(String stage) {
    return 'Показать объявления: $stage';
  }

  @override
  String get myListingsChannelPublishedLabel => 'Опубликовано';

  @override
  String get myListingsChannelFailedLabel => 'Ошибка';

  @override
  String get myListingsChannelPendingLabel => 'Публикуется…';

  @override
  String get myListingsChannelNotPublishedLabel => 'Не опубликовано';

  @override
  String myListingsChannelBadgeSemanticsLabel(String channel, String status) {
    return '$channel — $status';
  }

  @override
  String get agentsDirectoryScreenTitle => 'Риелторы';

  @override
  String get agentsDirectoryLoadErrorMessage =>
      'Не удалось загрузить риелторов';

  @override
  String get agentsDirectoryEmptyMessage => 'Риелторы не найдены.';

  @override
  String agentsCardAdsCountLabel(int count) {
    return 'Объявления: $count';
  }

  @override
  String get agentsProfileNavBackLabel => 'Назад';

  @override
  String get agentsProfileScreenTitle => 'Информация о риелторе';

  @override
  String get agentsProfileLoadErrorMessage => 'Не удалось загрузить риелтора';

  @override
  String get agentsProfileNotFoundMessage => 'Этот риелтор больше недоступен.';

  @override
  String get agentsProfileGoBackLabel => 'Назад';

  @override
  String get agentsInfoFullNameLabel => 'Полное имя:';

  @override
  String get agentsInfoEmailLabel => 'Email:';

  @override
  String get agentsInfoPhoneLabel => 'Телефон:';

  @override
  String get agentsInfoAddressLabel => 'Адрес:';

  @override
  String get agentsInfoRatingLabel => 'Рейтинг:';

  @override
  String get agentsInfoCallButtonLabel => 'Позвонить';

  @override
  String get agentsInfoMessageButtonLabel => 'Сообщение';

  @override
  String get agentsAdsGridLoadErrorMessage =>
      'Не удалось загрузить объявления риелтора';

  @override
  String get agentsAdsGridEmptyMessage => 'Объявления не найдены.';

  @override
  String get agentsAdsGridHeading => 'Список объявлений';

  @override
  String get reviewsRatingRequiredError => 'Пожалуйста, выберите рейтинг.';

  @override
  String get reviewsUpdateSuccessToast => 'Отзыв обновлён.';

  @override
  String get reviewsPostSuccessToast => 'Отзыв опубликован.';

  @override
  String get reviewsDeleteSuccessToast => 'Отзыв удалён.';

  @override
  String get reviewsSelfReviewForbiddenError =>
      'Вы не можете оставить отзыв о себе.';

  @override
  String get reviewsAgentNotFoundError => 'Этот риелтор больше недоступен.';

  @override
  String get reviewsSaveGenericErrorMessage =>
      'Не удалось сохранить ваш отзыв. Попробуйте ещё раз.';

  @override
  String get reviewsNetworkErrorMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get reviewsSheetEditTitle => 'Редактировать отзыв';

  @override
  String get reviewsSheetLeaveTitle => 'Оставить отзыв';

  @override
  String get reviewsSheetCloseLabel => 'Закрыть';

  @override
  String reviewsSheetPromptMessage(String agentName) {
    return 'Поделитесь своим опытом работы с $agentName.';
  }

  @override
  String get reviewsSheetCommentLabel => 'КОММЕНТАРИЙ (НЕОБЯЗАТЕЛЬНО)';

  @override
  String get reviewsSheetCommentHint =>
      'Каково было работать с этим риелтором?';

  @override
  String get reviewsSheetUpdateButtonLabel => 'Обновить отзыв';

  @override
  String get reviewsSheetPostButtonLabel => 'Опубликовать отзыв';

  @override
  String get reviewsSheetDeletingLabel => 'Удаление…';

  @override
  String get reviewsSheetDeleteButtonLabel => 'Удалить отзыв';

  @override
  String reviewsSectionHeading(int count) {
    return 'Отзывы ($count)';
  }

  @override
  String get reviewsSectionLoadErrorMessage =>
      'Не удалось загрузить отзывы о риелторе';

  @override
  String get reviewsSectionEmptyMessage => 'Пока нет отзывов.';

  @override
  String get reviewsSectionSignInPromptMessage =>
      'Войдите, чтобы оставить отзыв.';

  @override
  String get reviewsSectionSignInButtonLabel => 'Войти';

  @override
  String get reviewsSectionSelfProfileMessage =>
      'Вы не можете оставить отзыв о собственном профиле.';

  @override
  String get reviewsSectionLeaveButtonLabel => 'Оставить отзыв';

  @override
  String get reviewsSectionEditButtonLabel => 'Редактировать ваш отзыв';

  @override
  String get reviewsSectionLoadMoreLabel => 'Показать больше отзывов';

  @override
  String get profileAgentScreenTitle => 'Профиль';

  @override
  String get profileAgentAccountGroupLabel => 'Аккаунт';

  @override
  String get profileAgentEditProfileRowTitle => 'Редактировать профиль';

  @override
  String get profileAgentConnectedAccountsRowTitle => 'Подключённые аккаунты';

  @override
  String get profileAgentSettingsRowTitle => 'Настройки';

  @override
  String get profileAgentMessagesRowTitle => 'Сообщения';

  @override
  String get profileAgentLanguageRowTitle => 'Язык';

  @override
  String get profileAgentWorkspaceGroupLabel => 'Рабочий кабинет';

  @override
  String get profileAgentBrowseModeRowTitle => 'Смотреть объявления';

  @override
  String get profileAgentBrowseModeRowSubtitle => 'Ищите и смотрите как клиент';

  @override
  String get profileAgentWorkModeRowTitle => 'Перейти в кабинет';

  @override
  String get profileAgentWorkModeRowSubtitle =>
      'Статистика, объявления, лиды и коллеги';

  @override
  String get profileAgentSessionGroupLabel => 'Сессия';

  @override
  String get profileAgentLogoutRowTitle => 'Выйти';

  @override
  String get profileBuyerScreenTitle => 'Профиль';

  @override
  String get profileBuyerAccountGroupLabel => 'Аккаунт';

  @override
  String get profileBuyerSavedListingsRowTitle => 'Сохранённые объявления';

  @override
  String profileBuyerSavedListingsRowSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count объявлений',
      few: '$count объявления',
      one: '$count объявление',
      zero: 'Нет объявлений',
    );
    return '$_temp0';
  }

  @override
  String get profileBuyerUpdateProfileRowTitle => 'Обновить профиль';

  @override
  String get profileBuyerLanguageRowTitle => 'Язык';

  @override
  String get profileBuyerRegisterAsAgentRowTitle =>
      'Зарегистрироваться как риелтор';

  @override
  String get profileBuyerRealtorPendingRowTitle =>
      'Заявка риелтора на рассмотрении';

  @override
  String profileBuyerRealtorPendingRowSubtitle(String phone) {
    return 'Мы позвоним на $phone — обычно в течение одного рабочего дня.';
  }

  @override
  String get profileBuyerRealtorPendingNoPhoneSubtitle =>
      'Мы вам позвоним — обычно в течение одного рабочего дня.';

  @override
  String get profileBuyerRealtorRejectedRowTitle =>
      'Заявка риелтора не одобрена';

  @override
  String get profileBuyerRealtorRejectedRowSubtitle =>
      'Свяжитесь с нами, и мы разберём это вместе с вами.';

  @override
  String get profileBuyerRealtorRejectedActionLabel => 'Связаться с нами';

  @override
  String profileBuyerRealtorAppliedAtLabel(String date) {
    return 'Заявка от $date';
  }

  @override
  String get profileBuyerSessionGroupLabel => 'Сессия';

  @override
  String get profileBuyerLogoutRowTitle => 'Выйти';

  @override
  String get profileBuyerRegisterLinkCopiedToast =>
      'Не удалось открыть браузер — вместо этого скопирована ссылка на форму регистрации. Вставьте её в браузер, чтобы подать заявку.';

  @override
  String get profileSignedOutScreenTitle => 'Профиль';

  @override
  String get profileSignedOutPreferencesGroupLabel => 'Настройки';

  @override
  String get profileSignedOutLanguageRowTitle => 'Язык';

  @override
  String get profileSignedOutContactUsRowTitle => 'Связаться с нами';

  @override
  String get profileSignedOutPromptMessage =>
      'Войдите, чтобы сохранять объявления, писать риелторам и управлять своим бизнесом.';

  @override
  String get profileSignedOutSignInButtonLabel => 'Войти';

  @override
  String get profileSignedOutSignUpButtonLabel => 'Зарегистрироваться';

  @override
  String get authLoginRequiredFieldsError => 'Обязательные поля не заполнены';

  @override
  String get authLoginSuccessToast => 'Пользователь успешно вошёл в систему.';

  @override
  String get authLoginInvalidCredentialsError => 'Неверный email или пароль';

  @override
  String get authLoginForgotPasswordHintMessage =>
      'Забыли его? Нажмите «Забыли пароль?».';

  @override
  String get authLoginNetworkErrorMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get authLoginGenericErrorMessage => 'Что-то пошло не так';

  @override
  String get authLoginWelcomeHeading => 'С возвращением';

  @override
  String get authLoginEmailFieldLabel => 'Email';

  @override
  String get authLoginPasswordFieldLabel => 'Пароль';

  @override
  String get authLoginSubmitButtonLabel => 'Войти';

  @override
  String get authLoginForgotPasswordLinkLabel => 'Забыли пароль?';

  @override
  String authLoginForgotPasswordContactMessage(String email) {
    return 'Я забыл(а) пароль от $email и не могу войти. Пожалуйста, помогите его сбросить.';
  }

  @override
  String get authLoginForgotPasswordContactMessageNoEmail =>
      'Я забыл(а) пароль и не могу войти. Пожалуйста, помогите его сбросить.';

  @override
  String get authLoginFooterLinkText => 'Нет аккаунта?';

  @override
  String get authRegisterHeading => 'Создайте аккаунт';

  @override
  String get authRegisterAccountTypeLabel => 'Я регистрируюсь как';

  @override
  String get authRegisterBuyerCardTitle => 'Покупатель';

  @override
  String get authRegisterBuyerCardSubtitle =>
      'Просматривайте и сохраняйте дома';

  @override
  String get authRegisterRealtorCardTitle => 'Риелтор';

  @override
  String get authRegisterRealtorCardSubtitle =>
      'Публикуйте объявления, работайте с лидами';

  @override
  String get authRegisterFullNameFieldLabel => 'Полное имя';

  @override
  String get authRegisterPhoneFieldLabel => 'Номер телефона';

  @override
  String get authRegisterEmailFieldLabel => 'Email';

  @override
  String get authRegisterPasswordFieldLabel => 'Пароль';

  @override
  String get authRegisterPasswordHint => 'Не менее 6 символов';

  @override
  String get authRegisterRealtorTypeLabel => 'Тип риелтора';

  @override
  String get authRegisterSoloAgentChipLabel => 'Частный риелтор';

  @override
  String get authRegisterAgencyChipLabel => 'Агентство';

  @override
  String get authRegisterSoloAgentHint =>
      'Вы работаете под собственным именем. Ваше рабочее пространство открывается на разделе «Статистика» с вашими объявлениями и лидами; раздел «Коллеги» остаётся скрытым, пока вы не перейдёте на агентство.';

  @override
  String get authRegisterAgencyNameFieldLabel => 'Название агентства';

  @override
  String get authRegisterAgencyNameHelperText =>
      'Отображается в объявлениях команды вместо имени риелтора.';

  @override
  String get authRegisterOfficePhoneFieldLabel => 'Телефон офиса';

  @override
  String get authRegisterTeamSizeLabel => 'Размер команды';

  @override
  String get authRegisterTeamSizeJustMeLabel => 'Пока только я';

  @override
  String get authRegisterTeamSizeTwoToFiveLabel => '2–5';

  @override
  String get authRegisterTeamSizeSixToFifteenLabel => '6–15';

  @override
  String get authRegisterTeamSizeSixteenPlusLabel => '16+';

  @override
  String get authRegisterAgencyOwnerHint =>
      'Вы регистрируетесь как владелец агентства: приглашайте коллег, назначайте им лиды и видите статистику всей команды. Коллеги видят только то, что вы им назначили.';

  @override
  String get authRegisterVerificationCalloutMessage =>
      'Аккаунты риелторов проверяются до открытия вкладки «Работа». Мы позвоним по указанному выше номеру — обычно в течение одного рабочего дня.';

  @override
  String get authRegisterRequiredFieldsError =>
      'Обязательные поля не заполнены';

  @override
  String get authRegisterInvalidPhoneError => 'Неверный формат номера телефона';

  @override
  String get authRegisterFullNameRequiredError => 'Укажите полное имя';

  @override
  String get authRegisterPhoneRequiredError => 'Укажите номер телефона';

  @override
  String get authRegisterEmailRequiredError => 'Укажите email';

  @override
  String get authRegisterEmailInvalidError => 'Неверный формат адреса email';

  @override
  String get authRegisterPasswordRequiredError => 'Укажите пароль';

  @override
  String get authRegisterPasswordTooShortError =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get authRegisterAgencyNameRequiredError =>
      'Укажите название агентства';

  @override
  String get authRegisterRealtorSuccessToast =>
      'Аккаунт создан. Мы скоро проверим ваш профиль риелтора.';

  @override
  String get authRegisterBuyerSuccessToast => 'Пользователь успешно создан.';

  @override
  String get authRegisterNetworkErrorMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get authRegisterGenericErrorMessage => 'Что-то пошло не так';

  @override
  String get authRegisterRealtorSubmitButtonLabel => 'Создать аккаунт риелтора';

  @override
  String get authRegisterBuyerSubmitButtonLabel => 'Зарегистрироваться';

  @override
  String get authRegisterFooterLinkText => 'Уже есть аккаунт? Войти';

  @override
  String get authVisibilityToggleShowLabel => 'Показать пароль';

  @override
  String get authVisibilityToggleHideLabel => 'Скрыть пароль';

  @override
  String get authCloseButtonLabel => 'Закрыть';

  @override
  String get editProfileScreenTitle => 'Редактировать профиль';

  @override
  String get editProfileDiscardDialogTitle => 'Отменить изменения?';

  @override
  String get editProfileDiscardDialogCancelButtonLabel => 'Отмена';

  @override
  String get editProfileDiscardDialogConfirmButtonLabel => 'Не сохранять';

  @override
  String get editProfileAvatarUploadingToast =>
      'Пожалуйста, дождитесь завершения загрузки фото.';

  @override
  String get editProfileUpdateSuccessToast => 'Профиль успешно обновлён!';

  @override
  String editProfileUpdateErrorToast(String message) {
    return 'Ошибка обновления профиля: $message';
  }

  @override
  String get editProfileNetworkErrorMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get editProfileGenericErrorMessage => 'Что-то пошло не так';

  @override
  String get editProfileSignedOutMessage =>
      'Войдите, чтобы редактировать профиль.';

  @override
  String get editProfileSignedOutGoBackLabel => 'Назад';

  @override
  String get editProfileFullNameFieldLabel => 'Полное имя';

  @override
  String get editProfileFullNameRequiredError => 'Укажите имя';

  @override
  String get editProfilePhoneFieldLabel => 'Телефон';

  @override
  String get editProfilePhoneInvalidError =>
      'Неверный номер телефона Узбекистана';

  @override
  String get editProfileEmailFieldLabel => 'Email';

  @override
  String get editProfileEmailRequiredError => 'Укажите email';

  @override
  String get editProfilePasswordFieldLabel => 'Пароль';

  @override
  String get editProfilePasswordHint =>
      'Оставьте пустым, чтобы сохранить текущий пароль';

  @override
  String get editProfilePasswordLengthError =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get editProfileCancelButtonLabel => 'Отмена';

  @override
  String get editProfileSaveButtonLabel => 'Сохранить';

  @override
  String get contactRequiredFieldsError => 'Обязательные поля не заполнены';

  @override
  String get contactInvalidPhoneError => 'Неверный формат номера телефона';

  @override
  String get contactSendSuccessToast => 'Сообщение успешно отправлено.';

  @override
  String get contactRateLimitedError =>
      'Слишком много сообщений за раз. Попробуйте снова через минуту.';

  @override
  String get contactUnconfiguredError =>
      'Форма обратной связи сейчас недоступна. Пожалуйста, позвоните риелтору напрямую.';

  @override
  String get contactGenericErrorMessage =>
      'Не удалось отправить сообщение. Попробуйте ещё раз.';

  @override
  String get contactNetworkErrorMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get contactSheetTitle => 'Связаться с нами';

  @override
  String get contactSheetCloseLabel => 'Закрыть';

  @override
  String get contactSheetSubtitle =>
      'Мы рады любым вашим замечаниям, вопросам и предложениям. Свяжитесь с нами в удобное для вас время.';

  @override
  String get contactFullNameFieldLabel => 'Полное имя';

  @override
  String get contactPhoneFieldLabel => 'Телефон';

  @override
  String get contactMessageFieldLabel => 'Сообщение';

  @override
  String get contactMessageFieldHintText =>
      'Хотелось бы посмотреть эту квартиру на этой неделе.';

  @override
  String get contactSendButtonLabel => 'Отправить сообщение';

  @override
  String reviewsRatingInputStarLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
    );
    return '$_temp0';
  }

  @override
  String get leadsListScreenTitle => 'Лиды';

  @override
  String get leadsKanbanScreenTitle => 'Канбан';

  @override
  String get leadsToggleViewKanbanLabel => 'Показать как канбан';

  @override
  String get leadsToggleViewListLabel => 'Показать как список';

  @override
  String get leadsAddNewLeadLabel => 'Добавить лид';

  @override
  String get leadsEmptyMessage => 'Пока нет лидов.';

  @override
  String get leadsLoadErrorMessage => 'Не удалось загрузить ваши лиды.';

  @override
  String get leadsEmptyColumnMessage => 'На этом этапе пока нет лидов.';

  @override
  String get leadsCardMoveFailedMessage =>
      'Не удалось переместить — попробуйте снова.';

  @override
  String get leadsCardMoveFailedLabel => 'Не удалось переместить';

  @override
  String leadsCardMoveRetrySemanticsLabel(String status) {
    return 'Повторить перемещение в «$status»';
  }

  @override
  String get leadsCreateScreenTitle => 'Создать лид';

  @override
  String get leadsFieldFullNameLabel => 'Полное имя';

  @override
  String get leadsFieldPhoneLabel => 'Телефон';

  @override
  String get leadsFieldEmailLabel => 'Email';

  @override
  String get leadsFieldBudgetLabel => 'Бюджет';

  @override
  String get leadsFieldCommitLabel => 'Комментарий';

  @override
  String get leadsFieldSourceLabel => 'Источник';

  @override
  String get leadsCreateCommitHint => 'Что они ищут?';

  @override
  String get leadsCreateFullNameRequiredError => 'Укажите имя';

  @override
  String get leadsCreatePhoneRequiredError => 'Укажите номер телефона';

  @override
  String get leadsPhoneInvalidError => 'Неверный номер телефона Узбекистана';

  @override
  String get leadsDetailFullNameRequiredError => 'Укажите полное имя';

  @override
  String get leadsBudgetInvalidError => 'Введите корректное число';

  @override
  String get leadsStatusFieldLabel => 'СТАТУС';

  @override
  String get leadsCallTimeLabel => 'ВРЕМЯ ЗВОНКА';

  @override
  String get leadsSelectDateLabel => 'Выберите дату';

  @override
  String get leadsCoworkerFieldLabel => 'КОЛЛЕГА';

  @override
  String get leadsCoworkerUnavailableNote =>
      'Назначение коллеги пока недоступно в этой версии.';

  @override
  String get leadsCancelButtonLabel => 'Отмена';

  @override
  String get leadsSaveButtonLabel => 'Сохранить';

  @override
  String get leadsCreatedToastMessage => 'Лид успешно создан!';

  @override
  String leadsCreateErrorToastMessage(String message) {
    return 'Ошибка при создании лида: $message';
  }

  @override
  String get leadsUpdatedToastMessage => 'Лид успешно обновлён!';

  @override
  String leadsUpdateErrorToastMessage(String message) {
    return 'Ошибка при обновлении лида: $message';
  }

  @override
  String get leadsDeletedToastMessage => 'Лид успешно удалён!';

  @override
  String leadsDeleteErrorToastMessage(String message) {
    return 'Ошибка при удалении лида: $message';
  }

  @override
  String get leadsNoConnectionMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get leadsSubjectNoun => 'лид';

  @override
  String get leadsDetailCloseLabel => 'Закрыть';

  @override
  String get leadsCallButtonLabel => 'Позвонить';

  @override
  String leadsCallSemanticsLabel(String phone) {
    return 'Позвонить: $phone';
  }

  @override
  String get leadsDetailLoadErrorMessage => 'Не удалось загрузить этот лид.';

  @override
  String get leadsDeleteLeadButtonLabel => 'Удалить';

  @override
  String leadsCommitMinLengthError(int min) {
    return 'Минимум $min символов.';
  }

  @override
  String get leadsCallbackSheetTitle => 'Укажите время следующего звонка';

  @override
  String get leadsConversationSheetTitle => 'Кратко опишите разговор';

  @override
  String get leadsConversationHint => 'Не менее 10 символов';

  @override
  String get leadsMoveToSheetTitle => 'Переместить…';

  @override
  String get coworkersListScreenTitle => 'Коллеги';

  @override
  String get coworkersLoadErrorMessage => 'Не удалось загрузить ваших коллег';

  @override
  String get coworkersEmptyMessage => 'Пока нет коллег.';

  @override
  String get coworkersEmptyStateActionLabel => 'Добавить коллегу';

  @override
  String get coworkersAddNewButtonLabel => '+ Добавить коллегу';

  @override
  String coworkersListingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count объявления',
      many: '$count объявлений',
      few: '$count объявления',
      one: '$count объявление',
    );
    return '$_temp0';
  }

  @override
  String get coworkersCreateScreenTitle => 'Создать коллегу';

  @override
  String get coworkersUploadWaitMessage =>
      'Дождитесь завершения загрузки фото.';

  @override
  String get coworkersUploadingToastLabel => 'Загрузка';

  @override
  String get coworkersCreatedToastMessage => 'Коллега успешно создан';

  @override
  String coworkersCreateErrorToastMessage(String message) {
    return 'Ошибка при создании коллеги: $message';
  }

  @override
  String get coworkersNoConnectionMessage =>
      'Нет соединения. Проверьте сеть и попробуйте снова.';

  @override
  String get coworkersGenericErrorMessage => 'Что-то пошло не так';

  @override
  String get coworkersSignInPromptMessage =>
      'Войдите, чтобы управлять своей командой.';

  @override
  String get coworkersSignInActionLabel => 'Войти';

  @override
  String get coworkersAgentOnlyMessage =>
      'Только риелторы могут добавлять коллег.';

  @override
  String get coworkersGoBackLabel => 'Назад';

  @override
  String get coworkersSoloAgentMessage =>
      'У индивидуальных риелторов нет команды. Чтобы добавлять коллег, переключитесь на аккаунт агентства.';

  @override
  String get coworkersAddPhotoLabel => 'Добавить фото';

  @override
  String get coworkersChangePhotoLabel => 'Изменить фото';

  @override
  String get coworkersFieldFullNameLabel => 'Полное имя';

  @override
  String get coworkersFieldPhoneLabel => 'Телефон';

  @override
  String get coworkersFieldEmailLabel => 'Email';

  @override
  String get coworkersFieldPasswordLabel => 'Пароль';

  @override
  String get coworkersPasswordHint => 'Минимум 6 символов';

  @override
  String get coworkersPasswordHintKeepCurrent =>
      'Оставьте пустым, чтобы сохранить текущий';

  @override
  String get coworkersFullNameRequiredError => 'Укажите полное имя';

  @override
  String get coworkersPhoneRequiredError => 'Укажите номер телефона';

  @override
  String get coworkersPhoneInvalidError =>
      'Неверный номер телефона Узбекистана';

  @override
  String get coworkersEmailRequiredError => 'Укажите email';

  @override
  String get coworkersPasswordRequiredError => 'Укажите пароль';

  @override
  String get coworkersPasswordTooShortError =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get coworkersCancelButtonLabel => 'Отмена';

  @override
  String get coworkersSaveButtonLabel => 'Сохранить';

  @override
  String get coworkersDeleteButtonLabel => 'Удалить';

  @override
  String get coworkersSubjectNoun => 'коллегу';

  @override
  String get coworkersDetailScreenTitle => 'Изменить коллегу';

  @override
  String get coworkersNotFoundMessage => 'Этот коллега больше недоступен.';

  @override
  String get coworkersDetailLoadErrorMessage =>
      'Не удалось загрузить этого коллегу';

  @override
  String get coworkersUpdatedToastMessage => 'Коллега успешно обновлён!';

  @override
  String coworkersUpdateErrorToastMessage(String message) {
    return 'Ошибка при обновлении коллеги: $message';
  }

  @override
  String get coworkersDeletedToastMessage => 'Коллега успешно удалён!';

  @override
  String coworkersDeleteErrorToastMessage(String message) {
    return 'Ошибка при удалении коллеги: $message';
  }

  @override
  String get coworkersReadOnlyNoteMessage =>
      'Только риелторы могут редактировать или удалять коллег.';

  @override
  String get coworkersActivityJustNow => 'Только что';

  @override
  String coworkersActivityMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин. назад',
    );
    return '$_temp0';
  }

  @override
  String coworkersActivityHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч. назад',
    );
    return '$_temp0';
  }

  @override
  String get coworkersActivityYesterday => 'Вчера';

  @override
  String coworkersActivityDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дн. назад',
    );
    return '$_temp0';
  }

  @override
  String get dashboardScreenHeaderTitle => 'Статистика';

  @override
  String get dashboardNotificationsSemanticsLabel => 'Уведомления';

  @override
  String get dashboardCoworkerStatisticsSectionTitle => 'Статистика коллег';

  @override
  String get dashboardWorkspaceGroupLabel => 'Рабочее пространство';

  @override
  String get dashboardAdsStatisticsTitle => 'Статистика объявлений';

  @override
  String get dashboardAdsStatisticsLoadErrorMessage =>
      'Не удалось загрузить статистику объявлений';

  @override
  String get dashboardNoDataForRangeMessage => 'Нет данных за этот период.';

  @override
  String get dashboardLegendCreated => 'Создано';

  @override
  String get dashboardLegendSold => 'Продано';

  @override
  String dashboardChartSemanticsLabel(String range, int created, int sold) {
    return 'Статистика объявлений, $range: создано — $created, продано — $sold';
  }

  @override
  String dashboardCaptionHour(String hour) {
    return 'Час $hour';
  }

  @override
  String dashboardCaptionHoursRange(String start, String end) {
    return 'Часы $start–$end';
  }

  @override
  String dashboardCaptionDay(int day) {
    return 'День $day';
  }

  @override
  String dashboardCaptionDaysRange(int start, int end) {
    return 'Дни $start–$end';
  }

  @override
  String dashboardCaptionAllTimeChartNote(String range) {
    return '$range · на графике этот месяц';
  }

  @override
  String get dashboardCoworkerStatisticsLoadErrorMessage =>
      'Не удалось загрузить статистику коллег';

  @override
  String get dashboardNoCoworkersMessage => 'Пока нет коллег.';

  @override
  String get dashboardAddCoworkerButtonLabel => 'Добавить коллегу';

  @override
  String get dashboardLegendAdsCount => 'Кол-во объявлений';

  @override
  String get dashboardLegendLeadCount => 'Кол-во лидов';

  @override
  String get dashboardLegendSaleCount => 'Кол-во продаж';

  @override
  String dashboardCoworkerBarsSemanticsLabel(
    String name,
    int ads,
    int leads,
    int sales,
  ) {
    return '$name: объявлений — $ads, лидов — $leads, продаж — $sales';
  }

  @override
  String get dashboardHeaderCoworkers => 'Коллеги';

  @override
  String get dashboardHeaderAds => 'Объявления';

  @override
  String get dashboardHeaderLeads => 'Лиды';

  @override
  String get dashboardHeaderSales => 'Продажи';

  @override
  String get dashboardTileAdsCreatedLabel => 'Создано объявлений';

  @override
  String get dashboardTileAdsSoldLabel => 'Продано объявлений';

  @override
  String get dashboardTileActiveLeadsLabel => 'Активные лиды';

  @override
  String get dashboardTileCoworkersLabel => 'Коллеги';

  @override
  String get dashboardTileTapToManageSubtitle => 'нажмите, чтобы управлять';

  @override
  String get dashboardTileTapToViewSubtitle => 'нажмите, чтобы посмотреть';

  @override
  String get dashboardRangeSubtitleAll => 'за всё время';

  @override
  String get dashboardRangeSubtitleThisMonth => 'за этот месяц';

  @override
  String get dashboardRangeSubtitleThisWeek => 'за эту неделю';

  @override
  String get dashboardRangeSubtitleToday => 'за сегодня';

  @override
  String dashboardCallbackSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count требуют звонка',
      many: '$count требуют звонка',
      few: '$count требуют звонка',
      one: '$count требует звонка',
    );
    return '$_temp0';
  }

  @override
  String get dashboardFilterLabelAll => 'Все';

  @override
  String get dashboardFilterLabelThisMonth => 'Этот месяц';

  @override
  String get dashboardFilterLabelThisWeek => 'Эта неделя';

  @override
  String get dashboardFilterLabelToday => 'Сегодня';

  @override
  String get dashboardWorkspaceMyAdsRowTitle => 'Мои объявления';

  @override
  String get dashboardWorkspaceLeadsRowTitle => 'Лиды';

  @override
  String get dashboardWorkspaceCoworkersRowTitle => 'Коллеги';

  @override
  String dashboardWorkspaceMyAdsSubtitle(int listings, int drafts) {
    return '$listings объявлений · $drafts черновиков';
  }

  @override
  String dashboardWorkspaceLeadsSubtitle(int active, int dueToday) {
    return '$active активных · $dueToday требуют звонка';
  }

  @override
  String dashboardWorkspaceCoworkersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count человек',
      many: '$count человек',
      few: '$count человека',
      one: '$count человек',
    );
    return '$_temp0';
  }

  @override
  String get notificationsScreenTitle => 'Уведомления';

  @override
  String get notificationsLoadErrorMessage =>
      'Не удалось загрузить ваши уведомления.';

  @override
  String get notificationsMarkAllReadLabel => 'Всё прочитано';

  @override
  String get notificationsMarkedAllReadToastMessage =>
      'Все уведомления отмечены прочитанными';

  @override
  String get notificationsMarkAllReadPendingLabel => 'Отмечаем прочитанными';

  @override
  String get notificationsMarkAllReadErrorMessage =>
      'Не удалось отметить уведомления прочитанными.';

  @override
  String get notificationsEmptyMessage => 'Пока нет уведомлений.';

  @override
  String get notificationsEmptyStateDetailMessage =>
      'Здесь появятся новые лиды, одобрения объявлений и результаты публикаций.';

  @override
  String get notificationsEmptyStateActionLabel => 'Обновить';

  @override
  String get notificationsAgentOnlyMessage =>
      'Уведомления доступны только риелторам.';

  @override
  String get notificationsSignInPromptMessage =>
      'Войдите, чтобы увидеть свои уведомления.';

  @override
  String get notificationsGoBackLabel => 'Назад';

  @override
  String notificationsUnreadSemanticsLabel(String title) {
    return '$title, непрочитано';
  }

  @override
  String get notificationsRelativeJustNow => 'Только что';

  @override
  String notificationsRelativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин. назад',
    );
    return '$_temp0';
  }

  @override
  String notificationsRelativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч. назад',
    );
    return '$_temp0';
  }

  @override
  String get notificationsRelativeYesterday => 'Вчера';

  @override
  String notificationsRelativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дн. назад',
    );
    return '$_temp0';
  }

  @override
  String get messagesScreenTitle => 'Сообщения';

  @override
  String get messagesComingSoonTitle => 'Обмен сообщениями скоро появится';

  @override
  String get messagesComingSoonBody =>
      'Пока связывайтесь с лидами по телефону. В карточке каждого лида есть номер для звонка в одно касание.';

  @override
  String get messagesOpenLeadsAction => 'Открыть лиды';

  @override
  String get connectedAccountsScreenTitle => 'Подключённые аккаунты';

  @override
  String get connectedAccountsInstagramToggleTitle =>
      'Создать пост в Instagram';

  @override
  String get connectedAccountsInstagramToggleSubtitle =>
      'Статус — включён, когда привязан хотя бы один аккаунт';

  @override
  String get connectedAccountsTelegramToggleTitle => 'Создать пост в Telegram';

  @override
  String get connectedAccountsTelegramToggleSubtitle =>
      'Статус — включён, когда привязан канал';

  @override
  String get connectedAccountsYoutubeToggleTitle => 'Создать пост в Youtube';

  @override
  String get connectedAccountsThreadsToggleTitle => 'Создать пост в Threads';

  @override
  String get connectedAccountsFacebookMarketplaceToggleTitle =>
      'Создать пост в Facebook Marketplace';

  @override
  String get connectedAccountsXToggleTitle => 'Создать пост в X';

  @override
  String get connectedAccountsLinkedinToggleTitle => 'Создать пост в LinkedIn';

  @override
  String get connectedAccountsInstagramLoadErrorMessage =>
      'Не удалось загрузить ваши аккаунты Instagram.';

  @override
  String get connectedAccountsAvatarFallbackName => 'Instagram';

  @override
  String get connectedAccountsDisconnectingToastLabel => 'Отключение';

  @override
  String get connectedAccountsDisconnectedToastMessage =>
      'Аккаунт Instagram отключён.';

  @override
  String get connectedAccountsFallbackAccountName => 'Аккаунт Instagram';

  @override
  String connectedAccountsDisconnectSemanticsLabel(String name) {
    return 'Отключить $name';
  }

  @override
  String get connectedAccountsDisconnectButtonLabel => 'Отключить';

  @override
  String connectedAccountsPostsStatLabel(int count) {
    return 'Публикации $count';
  }

  @override
  String connectedAccountsFollowersStatLabel(int count) {
    return 'Подписчики $count';
  }

  @override
  String connectedAccountsFollowingStatLabel(int count) {
    return 'Подписки $count';
  }

  @override
  String get connectedAccountsConnectButtonLabel => 'Подключить Instagram';

  @override
  String get connectedAccountsOpeningBrowserToastMessage =>
      'Вход в Instagram открывается в браузере.';

  @override
  String get connectedAccountsLinkCopiedToastMessage =>
      'Не удалось открыть браузер — ссылка для входа в Instagram скопирована. Вставьте её в браузер, чтобы подключиться.';

  @override
  String get connectedAccountsConnectionFailedToastMessage =>
      'Не удалось подключиться к Instagram — попробуйте снова.';

  @override
  String connectedAccountsTelegramChannelsConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count каналов подключено',
      many: '$count каналов подключено',
      few: '$count канала подключено',
      one: '$count канал подключён',
    );
    return '$_temp0';
  }

  @override
  String get connectedAccountsTelegramNoChannelsMessage =>
      'Нет подключённых каналов Telegram';

  @override
  String get connectedAccountsYoutubeAddAccountLabel => 'Добавить аккаунт';

  @override
  String get connectedAccountsYoutubeSignOutLabel => 'Выйти';

  @override
  String connectedAccountsUnavailableSemanticsSuffix(String label) {
    return '$label (недоступно в этой версии)';
  }

  @override
  String get connectedAccountsYoutubeBetaNoteMessage =>
      'Бета — недоступно в этой версии.';

  @override
  String get connectedAccountsThreadsUnavailableNoteMessage =>
      'Публикация в Threads требует профиля Threads, привязанного к профессиональному аккаунту Instagram, — эта сборка такой доступ не запрашивает.';

  @override
  String get connectedAccountsFacebookMarketplaceUnavailableNoteMessage =>
      'У Facebook Marketplace нет разрешённого способа автоматизации ни на одной платформе — объявления туда размещаются вручную.';

  @override
  String get connectedAccountsXUnavailableNoteMessage =>
      'Публикация в X требует отдельного приложения X API с платным тарифом на запись — ни того, ни другого в этой сборке нет.';

  @override
  String get connectedAccountsLinkedinUnavailableNoteMessage =>
      'Публикация в LinkedIn требует одобренного приложения LinkedIn Marketing API — в этой сборке нет учётных данных LinkedIn.';

  @override
  String get connectedAccountsConnectedStatusLabel => 'Подключено';

  @override
  String get connectedAccountsNotConnectedStatusLabel => 'Не подключено';

  @override
  String get connectedAccountsInstagramBrowserHint =>
      'Откроется системный браузер — Meta не разрешает OAuth внутри встроенного WebView.';

  @override
  String get connectedAccountsOtherChannelsHint =>
      'У OLX нет постоянного аккаунта для подключения — кросс-постинг в OLX работает только из десктопного приложения.';

  @override
  String get leadsCommitFieldUppercaseLabel => 'КОММЕНТАРИЙ';

  @override
  String get languageSheetTitle => 'Язык';

  @override
  String get languageSheetCloseLabel => 'Закрыть';

  @override
  String get galleryPreviousPhotoSemanticsLabel => 'Предыдущее фото';

  @override
  String get galleryNextPhotoSemanticsLabel => 'Следующее фото';

  @override
  String get contactPhoneFieldHint =>
      'Только номера Узбекистана — +998 и девять цифр.';

  @override
  String get leadsPhoneFormatHint =>
      'Только номера Узбекистана — +998 и девять цифр.';

  @override
  String get filterPriceAnyOptionLabel => 'Любая цена';

  @override
  String agentsAdsGridActiveCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активных',
      many: '$count активных',
      few: '$count активных',
      one: '$count активное',
    );
    return '$_temp0';
  }

  @override
  String get permissionsPrimerLeadBody =>
      'Два разрешения, запрашиваются один раз. Оба можно изменить позже в настройках.';

  @override
  String get authLoginLeadBody =>
      'Войдите, чтобы сохранять объявления, писать риелторам и вести свой бизнес.';

  @override
  String get authRegisterLeadBody =>
      'Просмотр, сохранение и сообщения работают в любом аккаунте. Аккаунт риелтора добавляет вкладку «Работа» — объявления, лиды и публикацию.';

  @override
  String get authRegisterFullNameHint => 'Dilnoza Yusupova';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get profileSignedOutContactUsRowSubtitle =>
      'Вопросы, проблемы и предложения';

  @override
  String get profileAgentEditProfileRowSubtitle =>
      'Аватар, имя, телефон, эл. почта';

  @override
  String get profileAgentConnectedAccountsRowSubtitle =>
      'Instagram, Telegram, YouTube';

  @override
  String get profileAgentSettingsRowSubtitle =>
      'Язык, уведомления, о приложении';

  @override
  String get profileAgentMessagesRowSubtitle => 'Скоро';

  @override
  String get profileBuyerUpdateProfileRowSubtitle =>
      'Имя, телефон, эл. почта, пароль';

  @override
  String get profileBuyerRegisterAsAgentRowSubtitle =>
      'Откроет Google Форму в браузере';

  @override
  String get settingsConnectedAccountsRowSubtitle =>
      'Instagram, Telegram, YouTube';

  @override
  String get settingsLogoutRowSubtitle => 'Потребуется войти снова';

  @override
  String get editProfilePasswordHelper =>
      'Не менее 6 символов. Нужен, только если вы его меняете.';

  @override
  String get sharedLoadMoreLoadingLabel => 'Загружаем ещё…';

  @override
  String get leadsKanbanLongPressHint =>
      'Нажмите и удерживайте карточку, чтобы переместить';

  @override
  String leadsCallBackFlagLabel(String when) {
    return 'Перезвонить $when';
  }

  @override
  String get leadsOptionalFieldHint => 'Необязательно';

  @override
  String leadsMoveToContextLine(String name, String status) {
    return '$name сейчас в «$status».';
  }
}
