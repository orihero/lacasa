/// Data-access seam for `contact-sheet` (SCREENS.md §3.11). Two
/// implementations: [FixtureContactRepository] (accepts and discards, no
/// network) and [LiveContactRepository] (`POST /api/contact`) — see
/// `contact_mode.dart` for which one is wired by default.
///
/// One method, and it either completes or throws. There is nothing to
/// return: the endpoint answers `202 {ok: true}`, which carries no
/// information the sheet doesn't already have.
library;

import '../../../api/api.dart';

abstract class ContactRepository {
  /// Submits the form. Completes normally on success; throws the same
  /// [ApiException] subtypes [LaCasaApi] throws so the sheet can map a
  /// `rateLimited`/`contactUnconfigured`/`contactRelayFailed` answer to
  /// copy the user can act on — see `contact_sheet.dart`'s error mapping.
  Future<void> submit(ContactRequest request);
}
