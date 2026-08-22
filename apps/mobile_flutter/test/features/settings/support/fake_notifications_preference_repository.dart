// In-memory [NotificationsPreferenceRepository] fake — same shape as
// `test/features/language/support/fake_language_repository.dart` — so no
// suite depends on a real keystore/keychain under `flutter test`.

import 'package:lacasa_mobile/features/settings/settings.dart';

class FakeNotificationsPreferenceRepository
    implements NotificationsPreferenceRepository {
  FakeNotificationsPreferenceRepository({bool initial = true})
    : _current = initial;

  bool _current;

  /// Every value [save] was called with, in call order.
  final List<bool> saved = [];

  @override
  Future<bool> load() async => _current;

  @override
  Future<void> save(bool enabled) async {
    _current = enabled;
    saved.add(enabled);
  }
}
