/// A do-nothing [ConnectedAccountsRepository] for tests that never look at
/// connected accounts but still mount something that reads them.
///
/// Every repository provider in `lib/` now builds a live implementation over
/// `LaCasaApi.create()` unconditionally — the old `Fixture*Repository` classes
/// and the `FLUTTER_TEST` switch in `lib/api/app_mode.dart` that forced them
/// are gone. Any widget test that builds the real router therefore mounts the
/// app shell, which touches nearly every repository, and any provider left
/// un-overridden fires real HTTP out of the test process — which shows up as a
/// `pumpAndSettle timed out` failure rather than anything that names the
/// culprit. This class exists purely to be that override: it answers every
/// call with the emptiest value its return type permits, immediately, and
/// never throws.
///
/// It is deliberately inert, and inertness is the whole contract — do not grow
/// it into a fixture. A test that actually exercises the `connected-accounts`
/// screen (SCREENS.md §21) wants observable behaviour: accounts to render, a
/// connect URL to assert on the clipboard, a disconnect it can record. Write a
/// purpose-built fake in `test/features/<feature>/support/` for that and
/// override the provider with it instead; leave this one for the ambient
/// background noise.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_misc/data/connected_accounts_repository.dart';

class InertConnectedAccountsRepository implements ConnectedAccountsRepository {
  const InertConnectedAccountsRepository();

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() async => const [];

  /// Non-nullable `String`, so the emptiest honest answer is `''`. Callers
  /// copy this to the clipboard (there is no `url_launcher` in this build),
  /// and copying an empty string is the inert outcome — no navigation, no
  /// fabricated Meta OAuth URL for a test to accidentally assert against.
  @override
  Future<String> instagramConnectUrl() async => '';

  @override
  Future<void> disconnectInstagram(String igUserId) async {}
}
