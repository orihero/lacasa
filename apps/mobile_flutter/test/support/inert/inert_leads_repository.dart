/// A do-nothing [LeadsRepository] for tests that mount a screen which reads
/// `leadsRepositoryProvider` incidentally rather than being about leads.
///
/// **Why this exists.** The bundled `FixtureLeadsRepository` is gone, and with
/// it the `lib/api/app_mode.dart` guard that forced fixtures under
/// `FLUTTER_TEST`. An un-overridden `leadsRepositoryProvider` now builds
/// `LiveLeadsRepository` around `LaCasaApi.create()` and fires real HTTP out
/// of the test process — which doesn't fail cleanly, it *hangs*, and the test
/// dies on `pumpAndSettle timed out` with nothing pointing at the cause. Any
/// test that pumps the real router shell touches this provider whether it
/// means to or not, so it needs something harmless sitting behind it.
///
/// Everything here is deliberately inert: no leads, no coworkers, writes that
/// succeed and return an empty placeholder. Nothing throws — a widget under
/// test should render its empty state, not an error state, and certainly not
/// an unhandled exception from a provider the test never mentioned.
///
/// **This is not a fake to assert against.** A test that wants real leads
/// behaviour — a populated list, a Kanban board with cards in columns, a
/// create/update round-trip it can verify — should override
/// `leadsRepositoryProvider` with a purpose-built fake from
/// `test/features/leads/support/` instead.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/data/leads_repository.dart';

class InertLeadsRepository implements LeadsRepository {
  const InertLeadsRepository();

  @override
  Future<List<Lead>> list() async => const <Lead>[];

  @override
  Future<Lead> getById(String id) async => _emptyLead(id);

  @override
  Future<Lead> create(LeadWriteInput input) async => _emptyLead('');

  @override
  Future<Lead> update(String id, LeadWriteInput input) async => _emptyLead(id);

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Coworker>> coworkers() async => const <Coworker>[];

  /// [Lead] is non-nullable on three of these methods and has no empty
  /// value of its own, so this builds the smallest one that is still a
  /// valid instance: blank strings, no phone/email/budget/notes, the
  /// [LeadStatus.newLead] a freshly created lead would carry, and epoch
  /// timestamps. [coworkerId] is `''` rather than `null` per the model's
  /// documented empty-string-not-null convention. It can't be `const`
  /// because [DateTime] has no const constructor.
  Lead _emptyLead(String id) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return Lead(
      id: id,
      fullName: '',
      phone: null,
      email: null,
      budget: null,
      comment: null,
      conversationComment: null,
      status: LeadStatus.newLead,
      source: null,
      callbackDate: null,
      active: true,
      agentId: '',
      coworkerId: '',
      createdAt: epoch,
      updatedAt: epoch,
    );
  }
}
