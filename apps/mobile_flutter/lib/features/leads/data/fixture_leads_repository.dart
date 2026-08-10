/// Offline stand-in for [LeadsRepository], backed by
/// `shared/fixtures/work_seed_data.dart`'s [workLeadsFixtures]/
/// [workCoworkersFixtures]. No network, no [LaCasaApi] dependency — this is
/// what every `leads` screen renders from by default (see
/// `leads_mode.dart`).
///
/// Holds a mutable in-memory copy of the seed list so create/update/delete
/// behave like a real backend for the lifetime of the app process (a fresh
/// launch resets back to the seed data) — the same "feels real, isn't
/// persisted" contract `FixtureFavouriteAdIdsRepository` documents for its
/// own mutable set.
library;

import '../../../api/api.dart';
import '../../../shared/fixtures/work_seed_data.dart';
import 'leads_repository.dart';

class FixtureLeadsRepository implements LeadsRepository {
  FixtureLeadsRepository() : _leads = [...workLeadsFixtures];

  final List<Lead> _leads;
  int _nextId = 9001;

  @override
  Future<List<Lead>> list() async => List.unmodifiable(_leads);

  @override
  Future<Lead> getById(String id) async {
    final lead = _leads.where((l) => l.id == id).firstOrNull;
    if (lead == null) throw _notFound(id);
    return lead;
  }

  @override
  Future<Lead> create(LeadWriteInput input) async {
    final now = DateTime.now();
    final lead = Lead(
      id: 'lead-fixture-${_nextId++}',
      fullName: input.fullName?.value ?? '',
      phone: input.phone?.value,
      email: input.email?.value,
      budget: input.budget?.value,
      comment: input.comment?.value,
      conversationComment: input.conversationComment?.value,
      // Matches `LeadsResource.create`'s own doc comment: an omitted
      // status defaults to `new` server-side.
      status: input.status?.value ?? LeadStatus.newLead,
      source: input.source?.value,
      callbackDate: input.callbackDate?.value,
      active: input.active?.value ?? true,
      // No real "current agent" concept exists across this app's fixture
      // universe (every Work fixture list mixes rows from all 3 seed
      // agents rather than scoping to one signed-in session) — see
      // `work_seed_data.dart`'s own doc comment. A fixed placeholder
      // keeps this fixture's shape valid without inventing a session this
      // build doesn't otherwise track.
      agentId: 'agent-javlon',
      coworkerId: '',
      createdAt: now,
      updatedAt: now,
    );
    // Newest first, matching the server's own `createdAt desc` ordering.
    _leads.insert(0, lead);
    return lead;
  }

  @override
  Future<Lead> update(String id, LeadWriteInput input) async {
    final index = _leads.indexWhere((l) => l.id == id);
    if (index == -1) throw _notFound(id);
    final existing = _leads[index];
    final updated = Lead(
      id: existing.id,
      fullName: input.fullName?.value ?? existing.fullName,
      phone: input.phone != null ? input.phone!.value : existing.phone,
      email: input.email != null ? input.email!.value : existing.email,
      budget: input.budget != null ? input.budget!.value : existing.budget,
      comment: input.comment != null ? input.comment!.value : existing.comment,
      conversationComment: input.conversationComment != null
          ? input.conversationComment!.value
          : existing.conversationComment,
      status: input.status?.value ?? existing.status,
      source: input.source != null ? input.source!.value : existing.source,
      callbackDate: input.callbackDate != null
          ? input.callbackDate!.value
          : existing.callbackDate,
      active: input.active?.value ?? existing.active,
      agentId: existing.agentId,
      coworkerId: existing.coworkerId,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _leads[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    // The AGENT-only 403 is a server-side rule this fixture has no session
    // concept to enforce — `lead_detail_sheet.dart` hides the Delete
    // affordance for a coworker session itself, so this is never called by
    // one in fixture mode either.
    final removed = _leads.any((l) => l.id == id);
    if (!removed) throw _notFound(id);
    _leads.removeWhere((l) => l.id == id);
  }

  @override
  Future<List<Coworker>> coworkers() async => workCoworkersFixtures;

  ApiErrorException _notFound(String id) => ApiErrorException(
    body: ApiErrorBody(code: ApiErrorCode.notFound, message: 'Lead not found'),
    statusCode: 404,
  );
}
