/// A controllable [CoworkersRepository] fake for widget tests — no network,
/// no coupling to `fixture_coworkers_repository.dart`. Every method has its
/// own error hook and call counter, matching
/// `test/features/agents/support/fake_agents_repository.dart`'s own
/// reasoning: the whole point of this repository's method split (§6's
/// "independent providers per independently-failable section") is that an
/// `ads`/`activity` failure must not take the roster or the form down with
/// it, and a fake with one shared error flag could not express that at all.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/data/coworkers_repository.dart';

class FakeCoworkersRepository implements CoworkersRepository {
  FakeCoworkersRepository({
    List<Coworker>? coworkers,
    List<Ad>? ads,
    List<ActivityEvent>? activity,
    this.listError,
    this.getByIdError,
    this.createError,
    this.updateError,
    this.deleteError,
    this.adsError,
    this.activityError,
    this.hold,
  }) : coworkers = coworkers ?? [],
       seedAds = ads ?? const [],
       seedActivity = activity ?? const [];

  /// When set, every method awaits this before returning — the only way to
  /// observe a loading state in a widget test (see
  /// `fake_agents_repository.dart`'s identical field for why a bare `async`
  /// method with no real `await` never leaves a loading state on screen
  /// long enough to assert against).
  final Completer<void>? hold;

  final List<Coworker> coworkers;

  /// Backing rows for [ads]/[activity] — named apart from those two
  /// interface methods (a field can't share a name with an inherited
  /// method it isn't overriding).
  final List<Ad> seedAds;
  final List<ActivityEvent> seedActivity;

  final Object? listError;
  final Object? getByIdError;
  final Object? createError;
  final Object? updateError;
  final Object? deleteError;
  final Object? adsError;
  final Object? activityError;

  int listCallCount = 0;
  int getByIdCallCount = 0;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int adsCallCount = 0;
  int activityCallCount = 0;

  /// The arguments the most recent [create] call was made with, for tests
  /// asserting the form actually sent what the user typed.
  ({
    String fullName,
    String email,
    String password,
    String? phoneNumber,
    String? avatar,
  })?
  lastCreateArgs;

  /// The most recent [update] call's id and field set — [OptionalField]s
  /// preserved as-is so a test can distinguish "omitted" from "explicitly
  /// sent" the same way the real server does.
  String? lastUpdateId;
  OptionalField<String>? lastUpdateFullName;
  OptionalField<String>? lastUpdateEmail;
  OptionalField<String?>? lastUpdatePhoneNumber;
  OptionalField<String?>? lastUpdateAvatar;
  OptionalField<String>? lastUpdatePassword;

  String? lastDeleteId;

  @override
  Future<List<Coworker>> list() async {
    listCallCount++;
    if (hold != null) await hold!.future;
    if (listError != null) throw listError!;
    return List.of(coworkers);
  }

  @override
  Future<Coworker> getById(String id) async {
    getByIdCallCount++;
    if (hold != null) await hold!.future;
    if (getByIdError != null) throw getByIdError!;
    for (final candidate in coworkers) {
      if (candidate.id == id) return candidate;
    }
    throw ApiErrorException(
      statusCode: 404,
      body: const ApiErrorBody(
        code: ApiErrorCode.notFound,
        message: 'Coworker not found',
      ),
    );
  }

  @override
  Future<Coworker> create({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatar,
  }) async {
    createCallCount++;
    lastCreateArgs = (
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      avatar: avatar,
    );
    if (createError != null) throw createError!;
    final created = Coworker(
      id: 'coworker-new',
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      avatar: avatar,
      agentId: 'agent-a',
    );
    coworkers.add(created);
    return created;
  }

  @override
  Future<Coworker> update(
    String id, {
    OptionalField<String>? fullName,
    OptionalField<String>? email,
    OptionalField<String?>? phoneNumber,
    OptionalField<String?>? avatar,
    OptionalField<String>? password,
  }) async {
    updateCallCount++;
    lastUpdateId = id;
    lastUpdateFullName = fullName;
    lastUpdateEmail = email;
    lastUpdatePhoneNumber = phoneNumber;
    lastUpdateAvatar = avatar;
    lastUpdatePassword = password;
    if (updateError != null) throw updateError!;

    final index = coworkers.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw ApiErrorException(
        statusCode: 404,
        body: const ApiErrorBody(
          code: ApiErrorCode.notFound,
          message: 'Coworker not found',
        ),
      );
    }
    final current = coworkers[index];
    final updated = Coworker(
      id: current.id,
      fullName: fullName != null ? fullName.value : current.fullName,
      email: email != null ? email.value : current.email,
      phoneNumber: phoneNumber != null ? phoneNumber.value : current.phoneNumber,
      avatar: avatar != null ? avatar.value : current.avatar,
      agentId: current.agentId,
    );
    coworkers[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    lastDeleteId = id;
    if (deleteError != null) throw deleteError!;
    coworkers.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<Ad>> ads() async {
    adsCallCount++;
    if (adsError != null) throw adsError!;
    return seedAds;
  }

  @override
  Future<List<ActivityEvent>> activity() async {
    activityCallCount++;
    if (activityError != null) throw activityError!;
    return seedActivity;
  }
}
