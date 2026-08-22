/// A [ContactRepository] that accepts a submission and does nothing with it.
///
/// **Why this exists.** `contactRepositoryProvider` now unconditionally builds
/// [LiveContactRepository] around `LaCasaApi.create()`, so a widget test that
/// mounts the real router — which reaches the contact sheet from listing
/// detail and from the agent profile — would fire a real `POST /api/contact`
/// out of the test process. That does not fail cleanly, it hangs, and the
/// test dies on `pumpAndSettle timed out` with nothing pointing at the cause.
/// Overriding the provider with this class removes the network without
/// pretending to be a contact backend.
///
/// **What it does.** [submit] discards the request and completes normally. It
/// never throws, so a test that happens to tap "Send" gets the success path
/// rather than an unexpected error banner — but it also records nothing, so
/// there is no way to assert *what* was submitted.
///
/// **When not to use it.** If a test is about contact behaviour — that the
/// sheet sends the prefilled message, that a `rateLimited` failure maps to
/// the right copy — this class cannot express any of that. Write a
/// purpose-built fake under `test/features/contact/support/` and override the
/// provider with that instead. Inert fakes are for the repositories a screen
/// touches incidentally, never for the one under test.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/contact/data/contact_repository.dart';

class InertContactRepository implements ContactRepository {
  const InertContactRepository();

  @override
  Future<void> submit(ContactRequest request) async {}
}
