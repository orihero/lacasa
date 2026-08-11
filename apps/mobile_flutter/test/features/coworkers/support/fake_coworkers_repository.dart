/// A controllable [CoworkersRepository] fake for widget tests — no network,
/// no coupling to `fixture_coworkers_repository.dart`. Every method has its
/// own error hook and call counter, matching
/// `test/features/agents/support/fake_agents_repository.dart`'s own
/// reasoning: the whole point of this repository's method split (§6's
/// "independent providers per independently-failable section") is that a
/// [summary] failure must not take the roster or the form down with it, and
/// a fake with one shared error flag could not express that at all.
///
/// **[summary] used to be two methods here** ([ads]/[activity], each with
/// its own seed list and error hook) that a screen folded by `coworkerId`
/// itself. `coworkers_repository.dart` collapsed those into the one
/// server-folded [summary] aggregate (`GET /statistics/coworkers/summary`
/// now does the fold), so this fake collapses to match — but [seedAds]/
/// [seedActivity]/[adsError]/[activityError] all survive under their
/// original names as [summary]'s own raw material and failure hooks rather
/// than being renamed, since a caller composing this fake still wants to
/// hand it "these ads" / "these activity events" / "the ads half failed"
/// exactly as before; only the fold itself moved from two call sites
/// (`ads()`, `activity()`) into one ([summary]). Either error hook alone is
/// enough to fail the whole aggregate — matching the real endpoint, which
/// has no way to fail only its ads half or only its activity half, unlike
/// the two-method fold this replaced.
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
  int summaryCallCount = 0;

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

  /// Folds [seedAds]/[seedActivity] into one [CoworkerSummary] row per
  /// [coworkers] entry — the fake's own version of what
  /// `GET /statistics/coworkers/summary` computes server-side. Mirrors
  /// `FixtureCoworkersRepository.summary`'s fold exactly (adsCreatedCount
  /// from `Ad.coworkerId` matches, adsSoldCount from
  /// [ActivityEventStage.adSold] events, lastActiveAt as the latest
  /// [ActivityEvent.createdAt] across *any* stage), with one deliberate
  /// difference: [leadsCreatedCount] is always `0` here rather than folded
  /// from a seeded lead list, because nothing in this test group has ever
  /// needed a controllable lead count and adding an unused seed list/param
  /// pair would just be dead surface area — see this class's own
  /// constructor doc comment for the same "only what a test actually
  /// reaches for" reasoning applied to [seedAds]/[seedActivity].
  ///
  /// **A coworker with no matching rows in either seed list still gets a
  /// row here, every count genuinely `0`** — never omitted, and never
  /// conflated with the em-dash a caller renders for a fetch that hasn't
  /// resolved (or has errored) at all. That distinction lives entirely in
  /// [hold]/[adsError]/[activityError]: a genuinely-empty summary list
  /// resolves to real zeros, while an unresolved/failed [summary] call is
  /// what a screen reads as "—" (see `coworkers_list_screen.dart`'s and
  /// `coworker_detail_screen.dart`'s own `AsyncValue.when` — `loading`/
  /// `error` render the dash, `data` never fabricates one).
  @override
  Future<List<CoworkerSummary>> summary() async {
    summaryCallCount++;
    if (hold != null) await hold!.future;
    // Either half failing fails the whole aggregate — see this file's own
    // doc comment for why there is no way to fail only one of these two.
    if (adsError != null) throw adsError!;
    if (activityError != null) throw activityError!;

    return coworkers.map((coworker) {
      final events = seedActivity.where((e) => e.coworkerId == coworker.id);

      DateTime? lastActive;
      for (final event in events) {
        if (lastActive == null || event.createdAt.isAfter(lastActive)) {
          lastActive = event.createdAt;
        }
      }

      return CoworkerSummary(
        coworkerId: coworker.id,
        adsCreatedCount: seedAds
            .where((ad) => ad.coworkerId == coworker.id)
            .length,
        adsSoldCount: events
            .where((e) => e.stage == ActivityEventStage.adSold)
            .length,
        leadsCreatedCount: 0,
        lastActiveAt: lastActive,
      );
    }).toList(growable: false);
  }
}
