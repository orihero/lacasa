/// Offline stand-in for [ContactRepository]: accepts the submission and
/// discards it.
///
/// Read `contact_mode.dart` before shipping anything that uses this — a
/// form that reports success while sending nothing is a different and more
/// dangerous kind of stub than a feed that renders seed data.
library;

import '../../../api/api.dart';
import 'contact_repository.dart';

class FixtureContactRepository implements ContactRepository {
  const FixtureContactRepository();

  @override
  Future<void> submit(ContactRequest request) async {
    // Deliberately not instantaneous: the sheet has a submitting state with
    // a disabled button, and a synchronous success would make that
    // unreachable in practice and untested in a widget test that never
    // pumps between the tap and the result.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
