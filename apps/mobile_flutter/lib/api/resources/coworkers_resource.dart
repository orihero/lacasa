/// `/api/coworkers` — behind `coworkers-list` (§35), `coworker-detail`
/// (§36) and `add-coworker` (§37). Every route requires auth; create/
/// update/delete are AGENT-only (403 `forbidden` for a COWORKER caller).
library;

import '../api_client.dart';
import '../models/coworker.dart';
import '../models/optional_field.dart';

class CoworkersResource {
  final ApiClient _client;

  const CoworkersResource(this._client);

  /// `GET /api/coworkers` — `where {agentId, role: "COWORKER"}`, scoped to
  /// the caller's own team.
  Future<List<Coworker>> list() async {
    final json = await _client.request(method: 'GET', path: '/coworkers');
    return (json as List<dynamic>)
        .map((e) => Coworker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/coworkers/:id`. Throws [ApiErrorException] `code: notFound`
  /// (404) if absent or not on the caller's team.
  Future<Coworker> getById(String id) async {
    final json = await _client.request(method: 'GET', path: '/coworkers/$id');
    return Coworker.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /api/coworkers`. Throws [ApiErrorException] with:
  /// - `code: forbidden` (403) — caller is a COWORKER, or (`code:
  ///   solo_realtor`, not `forbidden` — see below) the caller is a SOLO
  ///   agent.
  /// - `code: solo_realtor` (403) — `"Solo agents don't have a team.
  ///   Switch to an agency account to add coworkers."`; check
  ///   `AuthUser.realtor?.kind` client-side to hide the "+ Add new
  ///   coworker" affordance for a solo agent rather than let this 403
  ///   surface as a surprise.
  /// - `code: validation` (400) — a zod issue on [fullName]/[email]/
  ///   [password]/[phoneNumber]/[avatar].
  /// - `code: emailTaken` (409) — [email] collides with an existing
  ///   account.
  Future<Coworker> create({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatar,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/coworkers',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': ?phoneNumber,
        'avatar': ?avatar,
      },
    );
    return Coworker.fromJson(json as Map<String, dynamic>);
  }

  /// `PATCH /api/coworkers/:id`. AGENT only (`code: forbidden`, 403,
  /// otherwise). Every param uses [OptionalField] (`models/optional_field.dart`)
  /// so a screen can distinguish "leave phone number alone" (omit) from
  /// "clear it" (`OptionalField(null)`) — **`phoneNumber`/`avatar` are the
  /// only two of these that are meaningfully nullable on the wire**;
  /// [fullName]/[email]/[password] should only ever be passed `OptionalField`
  /// with a non-null value (the server has no "clear to null" behavior for
  /// those three that would make sense).
  ///
  /// Throws `code: validation` (400, e.g. `password` under 6 chars),
  /// `code: notFound` (404), `code: emailTaken` (409).
  Future<Coworker> update(
    String id, {
    OptionalField<String>? fullName,
    OptionalField<String>? email,
    OptionalField<String?>? phoneNumber,
    OptionalField<String?>? avatar,
    OptionalField<String>? password,
  }) async {
    final json = await _client.request(
      method: 'PATCH',
      path: '/coworkers/$id',
      body: {
        ...optionalEntry('fullName', fullName),
        ...optionalEntry('email', email),
        ...optionalEntry('phoneNumber', phoneNumber),
        ...optionalEntry('avatar', avatar),
        ...optionalEntry('password', password),
      },
    );
    return Coworker.fromJson(json as Map<String, dynamic>);
  }

  /// `DELETE /api/coworkers/:id`. AGENT only. Throws `code: notFound` (404)
  /// if absent or not on the caller's team.
  Future<void> delete(String id) async {
    await _client.request(method: 'DELETE', path: '/coworkers/$id');
  }
}
