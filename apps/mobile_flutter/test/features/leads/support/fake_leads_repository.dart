/// A controllable [LeadsRepository] fake for widget tests — no network, no
/// coupling to `work_seed_data.dart`, same shape as
/// `test/features/saved_listings/support/fake_saved_listings_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/data/leads_repository.dart';

class FakeLeadsRepository implements LeadsRepository {
  FakeLeadsRepository({
    List<Lead>? leads,
    List<Coworker>? coworkers,
    this.listError,
    this.updateError,
    this.deleteError,
    this.createError,
    this.hold,
    this.updateHold,
  }) : _leads = [...(leads ?? const [])],
       _coworkers = coworkers ?? const [];

  final List<Lead> _leads;
  final List<Coworker> _coworkers;

  Object? listError;
  Object? updateError;
  Object? deleteError;
  Object? createError;

  /// When set, [list] awaits this before returning — the only way to
  /// observe a loading state in a widget test.
  final Completer<void>? hold;

  /// When set, [update] awaits this before returning/throwing — the only
  /// way to observe a Kanban card's own in-flight spinner in a widget test.
  final Completer<void>? updateHold;

  int listCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int createCallCount = 0;
  String? lastDeletedId;
  LeadWriteInput? lastUpdateInput;
  LeadWriteInput? lastCreateInput;

  @override
  Future<List<Lead>> list() async {
    listCallCount++;
    if (hold != null) await hold!.future;
    if (listError != null) throw listError!;
    return List.unmodifiable(_leads);
  }

  @override
  Future<Lead> getById(String id) async {
    final lead = _leads.where((l) => l.id == id).firstOrNull;
    if (lead == null) {
      throw ApiErrorException(
        body: const ApiErrorBody(code: ApiErrorCode.notFound, message: 'Lead not found'),
        statusCode: 404,
      );
    }
    return lead;
  }

  @override
  Future<Lead> create(LeadWriteInput input) async {
    createCallCount++;
    lastCreateInput = input;
    if (createError != null) throw createError!;
    final lead = Lead(
      id: 'lead-fake-$createCallCount',
      fullName: input.fullName?.value ?? '',
      phone: input.phone?.value,
      email: input.email?.value,
      budget: input.budget?.value,
      comment: input.comment?.value,
      conversationComment: input.conversationComment?.value,
      status: input.status?.value ?? LeadStatus.newLead,
      source: input.source?.value,
      callbackDate: input.callbackDate?.value,
      active: input.active?.value ?? true,
      agentId: 'agent-fake',
      coworkerId: '',
      createdAt: DateTime(2026, 8, 10),
      updatedAt: DateTime(2026, 8, 10),
    );
    _leads.insert(0, lead);
    return lead;
  }

  @override
  Future<Lead> update(String id, LeadWriteInput input) async {
    updateCallCount++;
    lastUpdateInput = input;
    if (updateHold != null) await updateHold!.future;
    if (updateError != null) throw updateError!;
    final index = _leads.indexWhere((l) => l.id == id);
    if (index == -1) {
      throw ApiErrorException(
        body: const ApiErrorBody(code: ApiErrorCode.notFound, message: 'Lead not found'),
        statusCode: 404,
      );
    }
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
      updatedAt: DateTime(2026, 8, 10),
    );
    _leads[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeletedId = id;
    if (deleteError != null) throw deleteError!;
    _leads.removeWhere((l) => l.id == id);
  }

  @override
  Future<List<Coworker>> coworkers() async => _coworkers;
}
