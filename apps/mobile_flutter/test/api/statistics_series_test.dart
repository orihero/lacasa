// StatisticsResource.series/coworkersSummary — correct method/path/query
// shaping and correct decoding, against a FakeTransport (no live network).

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

import 'support/fake_transport.dart';

ApiClient buildClient(FakeTransport transport, {String? token}) {
  return ApiClient(
    transport: transport,
    tokenStorage: InMemoryTokenStorage(token),
    baseUrl: 'https://api.example.com',
  );
}

void main() {
  group('StatisticsResource.series', () {
    test(
      'with no args sends no query params (server defaults to today)',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'granularity': 'hour',
            'from': {'seconds': 0},
            'to': {'seconds': 3600},
            'buckets': <Map<String, dynamic>>[],
          },
        );
        final statistics = StatisticsResource(
          buildClient(transport, token: 'tok'),
        );

        final series = await statistics.series();

        expect(transport.requests.single.method, 'GET');
        expect(
          transport.requests.single.url,
          'https://api.example.com/statistics/ads/series',
        );
        expect(transport.requests.single.query!['filterType'], isNull);
        expect(transport.requests.single.query!['from'], isNull);
        expect(transport.requests.single.query!['to'], isNull);
        expect(series.granularity, SeriesGranularity.hour);
      },
    );

    test('filterType is forwarded as its wire value', () async {
      final transport = FakeTransport(
        (req) async => {
          'granularity': 'day',
          'from': {'seconds': 0},
          'to': {'seconds': 0},
          'buckets': <Map<String, dynamic>>[],
        },
      );
      final statistics = StatisticsResource(
        buildClient(transport, token: 'tok'),
      );

      await statistics.series(filterType: StatisticsFilter.thisWeek);

      expect(transport.requests.single.query!['filterType'], 'thisWeek');
    });

    test(
      'from/to are sent as ISO-8601 strings and win over filterType',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'granularity': 'day',
            'from': {'seconds': 0},
            'to': {'seconds': 0},
            'buckets': <Map<String, dynamic>>[],
          },
        );
        final statistics = StatisticsResource(
          buildClient(transport, token: 'tok'),
        );
        final from = DateTime.utc(2026, 8, 1);
        final to = DateTime.utc(2026, 8, 8);

        await statistics.series(
          filterType: StatisticsFilter.today,
          from: from,
          to: to,
        );

        final query = transport.requests.single.query!;
        expect(query['from'], from.toIso8601String());
        expect(query['to'], to.toIso8601String());
        expect(query['filterType'], 'today');
      },
    );

    test('rethrows the 744-bucket-cap validation error unchanged', () async {
      final transport = FakeTransport(
        (req) async => throw ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.validation,
            message:
                'Requested range spans 1000 hour buckets, over the 744-bucket maximum',
          ),
          statusCode: 400,
        ),
      );
      final statistics = StatisticsResource(
        buildClient(transport, token: 'tok'),
      );

      await expectLater(
        statistics.series(),
        throwsA(
          isA<ApiErrorException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.validation,
          ),
        ),
      );
    });
  });

  group('StatisticsResource.coworkersSummary', () {
    test('GETs /statistics/coworkers/summary and decodes each row', () async {
      final transport = FakeTransport(
        (req) async => [
          {
            'coworkerId': 'coworker-1',
            'adsCreatedCount': 3,
            'adsSoldCount': 1,
            'leadsCreatedCount': 5,
            'lastActiveAt': {'seconds': 1700000000},
          },
          {
            'coworkerId': 'coworker-2',
            'adsCreatedCount': 0,
            'adsSoldCount': 0,
            'leadsCreatedCount': 0,
            'lastActiveAt': null,
          },
        ],
      );
      final statistics = StatisticsResource(
        buildClient(transport, token: 'tok'),
      );

      final summaries = await statistics.coworkersSummary();

      expect(
        transport.requests.single.url,
        'https://api.example.com/statistics/coworkers/summary',
      );
      expect(summaries, hasLength(2));
      expect(summaries[0].coworkerId, 'coworker-1');
      expect(summaries[1].lastActiveAt, isNull);
    });
  });
}
