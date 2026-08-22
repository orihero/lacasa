/// [NotificationsWatermarkRepository] backed by the platform
/// keystore/keychain via `flutter_secure_storage` — see that interface's doc
/// comment for why this needs to persist at all, and
/// `features/settings/data/secure_notifications_preference_repository.dart`/
/// `features/search/data/secure_recent_searches_repository.dart` for the
/// established pattern this copies: same package (already a project
/// dependency, no new one added for one more timestamp), same
/// never-throw-on-read degrade rule.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'notifications_watermark_repository.dart';

const String _watermarkKey = 'lacasa_notifications_watermark';

class SecureNotificationsWatermarkRepository
    implements NotificationsWatermarkRepository {
  SecureNotificationsWatermarkRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<DateTime?> load() async {
    try {
      final raw = await _storage.read(key: _watermarkKey);
      if (raw == null) return null;
      final millis = int.tryParse(raw);
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    } catch (_) {
      // A storage hiccup and "never opened this screen before" look
      // identical to the caller — both mean "no boundary," which is the
      // same degrade `SecureLanguageRepository.load` and
      // `SecureRecentSearchesRepository.load` make for their own reads.
      // Worst case this re-shows a row as unread that the agent already
      // saw once; it never hides one they haven't.
      return null;
    }
  }

  @override
  Future<void> save(DateTime watermark) async {
    try {
      await _storage.write(
        key: _watermarkKey,
        value: watermark.toUtc().millisecondsSinceEpoch.toString(),
      );
    } catch (_) {
      // A failed write just means the next open re-shows today's rows as
      // unread again — mildly annoying, never broken. Same call
      // `SecureNotificationsPreferenceRepository.save` makes.
    }
  }
}
