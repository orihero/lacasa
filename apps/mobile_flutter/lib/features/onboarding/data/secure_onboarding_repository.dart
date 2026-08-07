/// [OnboardingRepository] backed by the platform keystore/keychain via
/// `flutter_secure_storage`. See the interface's doc comment for why that
/// package rather than a new dependency, and why both failure paths answer
/// "seen".
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'onboarding_repository.dart';

const String _onboardingSeenKey = 'lacasa_onboarding_seen';

class SecureOnboardingRepository implements OnboardingRepository {
  SecureOnboardingRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasSeenOnboarding() async {
    try {
      return await _storage.read(key: _onboardingSeenKey) == 'true';
    } catch (_) {
      // Fail *closed* on the onboarding side: a returning user whose
      // keystore hiccups gets Home, not the pitch carousel again.
      return true;
    }
  }

  @override
  Future<void> markSeen() async {
    try {
      await _storage.write(key: _onboardingSeenKey, value: 'true');
    } catch (_) {
      // A failed write means the carousel shows once more next launch.
      // Mildly annoying, never broken — and there is nothing useful to
      // tell the user about their keychain at this moment.
    }
  }
}
