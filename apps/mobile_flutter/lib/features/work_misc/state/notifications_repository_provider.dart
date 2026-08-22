/// Picks [FixtureNotificationsRepository] or [LiveNotificationsRepository]
/// once, per `notifications_mode.dart`'s compile-time switch — same shape
/// as `features/agents/state/agents_repository_provider.dart`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../language/data/app_language.dart';
import '../../language/state/language_provider.dart';
import '../data/live_notifications_repository.dart';
import '../data/notifications_repository.dart';
import '../data/secure_notifications_watermark_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  // [LiveNotificationsRepository] formats a relative-time string
  // (`WorkNotification.relativeTime`) at fetch time, so it needs a
  // resolved [AppLocalizations] — but this is a plain `Provider`, not a
  // widget, so there is no `BuildContext` to call `AppLocalizations.of`
  // with. `lookupAppLocalizations` (generated alongside `AppLocalizations`
  // itself) resolves one directly from a [Locale], which is exactly what
  // [languageProvider] already tracks — same `AppLanguage.en` fallback
  // `app.dart` uses while that provider is still loading/failed, so the
  // very first notifications fetch (which can race the language read)
  // never fails to construct this repository.
  final language = ref.watch(languageProvider).value ?? AppLanguage.en;
  return LiveNotificationsRepository(
    LaCasaApi.create(),
    SecureNotificationsWatermarkRepository(),
    lookupAppLocalizations(Locale(language.wire)),
  );
});
