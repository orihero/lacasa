/// The one [NotificationsPreferenceRepository] every provider/widget reads
/// through — same shape as
/// `language/state/language_repository_provider.dart`. No fixture/live
/// split: this is a purely local preference, so a real keystore is the only
/// mode this ever runs in. Tests override this with an in-memory fake
/// instead (`test/features/settings/support/
/// fake_notifications_preference_repository.dart`) so no suite depends on a
/// real keystore/keychain being available under `flutter test`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_preference_repository.dart';
import '../data/secure_notifications_preference_repository.dart';

final notificationsPreferenceRepositoryProvider =
    Provider<NotificationsPreferenceRepository>((ref) {
      return SecureNotificationsPreferenceRepository();
    });
