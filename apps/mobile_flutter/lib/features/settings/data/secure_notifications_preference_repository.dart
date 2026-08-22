/// [NotificationsPreferenceRepository] backed by the platform
/// keystore/keychain via `flutter_secure_storage` — see that interface's
/// doc comment, and `language/data/secure_language_repository.dart`, for why
/// this package is reused rather than adding `shared_preferences` for one
/// more flag.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'notifications_preference_repository.dart';

const String _notificationsKey = 'lacasa_notifications_enabled';

class SecureNotificationsPreferenceRepository
    implements NotificationsPreferenceRepository {
  SecureNotificationsPreferenceRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<bool> load() async {
    try {
      final raw = await _storage.read(key: _notificationsKey);
      if (raw == null) return true;
      return raw == 'true';
    } catch (_) {
      // A storage hiccup and "never set anything" look identical to the
      // user, and neither is worth surfacing — same call
      // `SecureLanguageRepository.load` makes.
      return true;
    }
  }

  @override
  Future<void> save(bool enabled) async {
    try {
      await _storage.write(key: _notificationsKey, value: enabled.toString());
    } catch (_) {
      // A failed write just means the choice doesn't survive relaunch —
      // mildly annoying, never broken. Same call
      // `SecureLanguageRepository.save` makes.
    }
  }
}
