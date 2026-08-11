// LiveNotificationsRepository: a thin adapter over GET /notifications, whose
// two pieces of behaviour beyond forwarding are (1) the kind-mapping/skip
// rule for a row this client doesn't recognise, and (2) the client-side
// read-state watermark (load before the request, save only after it
// succeeds). Exercised against a FakeTransport (no real network) and an
// in-memory fake watermark repository (no platform channel).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_misc/data/live_notifications_repository.dart';
import 'package:lacasa_mobile/features/work_misc/data/notifications_watermark_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/shared.dart';

import '../../../api/support/fake_transport.dart';

// [LiveNotificationsRepository] now formats a relative-time string at fetch
// time (`_relativeTime`), so it needs a resolved [AppLocalizations] — see
// that file's own doc comment on why it's threaded in at construction
// rather than read from a `BuildContext`. `lookupAppLocalizations` (the
// same helper `notifications_repository_provider.dart` calls in the real
// app) resolves one directly from a [Locale], no widget tree needed.
final _l10n = lookupAppLocalizations(const Locale('en'));

class _FakeWatermarkRepository implements NotificationsWatermarkRepository {
  DateTime? stored;
  int saveCallCount = 0;

  @override
  Future<DateTime?> load() async => stored;

  @override
  Future<void> save(DateTime watermark) async {
    saveCallCount++;
    stored = watermark;
  }
}

Map<String, dynamic> _wire({
  required String id,
  required String kind,
  required String title,
  required int seconds,
  required bool unread,
  required String targetId,
}) => {
  'id': id,
  'kind': kind,
  'title': title,
  'createdAt': {'seconds': seconds},
  'unread': unread,
  'targetId': targetId,
};

void main() {
  late FakeTransport transport;
  late _FakeWatermarkRepository watermark;

  ApiClient buildClient() => ApiClient(
    transport: transport,
    tokenStorage: InMemoryTokenStorage('tok'),
    baseUrl: 'https://api.example.com',
  );

  setUp(() {
    watermark = _FakeWatermarkRepository();
  });

  test('a first-ever fetch omits since and every row maps through', () async {
    transport = FakeTransport(
      (req) async => [
        _wire(
          id: 'lead:l1:e1',
          kind: 'lead',
          title: 'New lead: A',
          seconds: 1700000000,
          unread: true,
          targetId: 'l1',
        ),
      ],
    );
    final repository = LiveNotificationsRepository(
      LaCasaApi(buildClient()),
      watermark,
      _l10n,
    );

    final result = await repository.fetchNotifications();

    expect(transport.requests.single.query!['since'], isNull);
    expect(result, hasLength(1));
    expect(result.single.id, 'lead:l1:e1');
    expect(result.single.kind, WorkNotificationKind.lead);
    expect(result.single.title, 'New lead: A');
    expect(result.single.unread, isTrue);
    expect(result.single.targetId, 'l1');
  });

  test('a stored watermark is sent as since, ISO-8601 encoded', () async {
    final stored = DateTime.utc(2026, 8, 1, 12, 0, 0);
    watermark.stored = stored;
    transport = FakeTransport((req) async => <Map<String, dynamic>>[]);
    final repository = LiveNotificationsRepository(
      LaCasaApi(buildClient()),
      watermark,
      _l10n,
    );

    await repository.fetchNotifications();

    expect(transport.requests.single.query!['since'], stored.toIso8601String());
  });

  test('a successful fetch saves a new watermark', () async {
    transport = FakeTransport((req) async => <Map<String, dynamic>>[]);
    final repository = LiveNotificationsRepository(
      LaCasaApi(buildClient()),
      watermark,
      _l10n,
    );

    final before = DateTime.now();
    await repository.fetchNotifications();
    final after = DateTime.now();

    expect(watermark.saveCallCount, 1);
    expect(watermark.stored, isNotNull);
    // "now" was captured somewhere between the call starting and finishing —
    // not brittle against the exact instant, just the right neighbourhood.
    expect(
      watermark.stored!.isAfter(before.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(
      watermark.stored!.isBefore(after.add(const Duration(seconds: 1))),
      isTrue,
    );
  });

  test('a failed fetch never touches the watermark', () async {
    watermark.stored = DateTime.utc(2026, 8, 1);
    transport = FakeTransport(
      (req) async => throw ApiErrorException(
        body: const ApiErrorBody(
          code: ApiErrorCode.forbidden,
          message: 'Not allowed for this role',
        ),
        statusCode: 403,
      ),
    );
    final repository = LiveNotificationsRepository(
      LaCasaApi(buildClient()),
      watermark,
      _l10n,
    );

    await expectLater(
      repository.fetchNotifications(),
      throwsA(isA<ApiErrorException>()),
    );
    expect(watermark.saveCallCount, 0);
    expect(watermark.stored, DateTime.utc(2026, 8, 1));
  });

  test(
    'an unrecognised kind is dropped rather than rendered with no icon',
    () async {
      transport = FakeTransport(
        (req) async => [
          _wire(
            id: 'weird:1',
            kind: 'something-future-added',
            title: 'A kind this build does not know',
            seconds: 1700000000,
            unread: true,
            targetId: 'x',
          ),
          _wire(
            id: 'sold:a1:e1',
            kind: 'sold',
            title: 'Listing sold — Flat marked as Sold',
            seconds: 1700000100,
            unread: false,
            targetId: 'a1',
          ),
        ],
      );
      final repository = LiveNotificationsRepository(
      LaCasaApi(buildClient()),
      watermark,
      _l10n,
    );

      final result = await repository.fetchNotifications();

      expect(result, hasLength(1));
      expect(result.single.id, 'sold:a1:e1');
    },
  );

  test('publish and coworkerActivity kinds map through too', () async {
    transport = FakeTransport(
      (req) async => [
        _wire(
          id: 'publish:a1:TELEGRAM:1700000000',
          kind: 'publish',
          title: 'Telegram post published — Flat is now live on Telegram',
          seconds: 1700000000,
          unread: true,
          targetId: 'a1',
        ),
        _wire(
          id: 'coworker:c1:e1',
          kind: 'coworkerActivity',
          title: 'Coworker added a new listing — B created Flat',
          seconds: 1700000000,
          unread: true,
          targetId: 'c1',
        ),
      ],
    );
    final repository = LiveNotificationsRepository(
      LaCasaApi(buildClient()),
      watermark,
      _l10n,
    );

    final result = await repository.fetchNotifications();

    expect(result.map((r) => r.kind), [
      WorkNotificationKind.publish,
      WorkNotificationKind.coworkerActivity,
    ]);
  });
}
