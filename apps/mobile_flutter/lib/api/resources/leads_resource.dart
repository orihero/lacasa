/// `/api/leads` — the full CRM lead CRUD surface behind `leads-list`
/// (§30), `leads-kanban` (§31), `lead-detail` (§32), `create-lead` (§33)
/// and `kanban-move-sheet` (§34). Every route requires auth and 403s for a
/// role that cannot resolve an `agentId` (plain `role: "user"`); a
/// COWORKER session sees the same full list as their agent, not just their
/// own leads (server-side scoping, not a client filter).
library;

import '../api_client.dart';
import '../models/lead.dart';
import '../models/lead_write_input.dart';

class LeadsResource {
  final ApiClient _client;

  const LeadsResource(this._client);

  /// `GET /api/leads`. No params, no pagination — the entire list every
  /// call, ordered `createdAt desc` server-side. Both `leads-list` and
  /// `leads-kanban` read from this one endpoint (see the web/console
  /// survey — there is no per-status endpoint).
  Future<List<Lead>> list() async {
    final json = await _client.request(method: 'GET', path: '/leads');
    return (json as List<dynamic>)
        .map((e) => Lead.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/leads/:id`. Throws [ApiErrorException] `code: notFound`
  /// (404) if absent or not owned by the caller's agent scope.
  Future<Lead> getById(String id) async {
    final json = await _client.request(method: 'GET', path: '/leads/$id');
    return Lead.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /api/leads`. Every field in [input] is optional — an omitted
  /// [LeadWriteInput.status] defaults to `LeadStatus.newLead` server-side.
  Future<Lead> create(LeadWriteInput input) async {
    final json = await _client.request(
      method: 'POST',
      path: '/leads',
      body: input.toJson(),
    );
    return Lead.fromJson(json as Map<String, dynamic>);
  }

  /// `PATCH /api/leads/:id`. Only keys present in [input] are touched —
  /// see [LeadWriteInput]'s own doc comment. **Every successful update
  /// unconditionally logs a `LEAD_STATUS_CHANGED` activity event
  /// server-side even when [input] never touches `status`** — a quirk of
  /// the API worth knowing if a caller is trying to reason about
  /// `GET /statistics/coworkers`'s event counts, not something this client
  /// can suppress.
  Future<Lead> update(String id, LeadWriteInput input) async {
    final json = await _client.request(
      method: 'PATCH',
      path: '/leads/$id',
      body: input.toJson(),
    );
    return Lead.fromJson(json as Map<String, dynamic>);
  }

  /// `DELETE /api/leads/:id`. Throws [ApiErrorException] with:
  /// - `code: forbidden` (403) — caller is a COWORKER; only the owning
  ///   AGENT may delete a lead.
  /// - `code: notFound` (404) — absent or not owned.
  Future<void> delete(String id) async {
    await _client.request(method: 'DELETE', path: '/leads/$id');
  }
}
