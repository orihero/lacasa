// Wire-shape decoding tests for this run's new/changed models: the
// notifications feed, the regions vocabulary, agent reviews, the
// statistics series/summary shapes, the ad paging envelope, and the
// AgentSummary/AgentDetail rating fields (null-vs-zero is load-bearing —
// see agent.dart's doc comment).

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('decodes every kind and an unread row', () {
      final n = AppNotification.fromJson({
        'id': 'lead:lead-1:event-9',
        'kind': 'lead',
        'title': 'New lead: Malika Tosheva',
        'createdAt': {'seconds': 1700000000},
        'unread': true,
        'targetId': 'lead-1',
      });

      expect(n.id, 'lead:lead-1:event-9');
      expect(n.kind, NotificationKind.lead);
      expect(n.unread, isTrue);
      expect(n.targetId, 'lead-1');
      expect(
        n.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
    });

    for (final pair in {
      'sold': NotificationKind.sold,
      'coworkerActivity': NotificationKind.coworkerActivity,
      'publish': NotificationKind.publish,
    }.entries) {
      test('decodes kind "${pair.key}"', () {
        final n = AppNotification.fromJson({
          'id': 'x',
          'kind': pair.key,
          'title': 't',
          'createdAt': {'seconds': 0},
          'unread': false,
          'targetId': 'y',
        });
        expect(n.kind, pair.value);
      });
    }

    test('an unrecognized kind decodes to unknown, not a throw', () {
      final n = AppNotification.fromJson({
        'id': 'x',
        'kind': 'somethingNew',
        'title': 't',
        'createdAt': {'seconds': 0},
        'unread': false,
        'targetId': 'y',
      });
      expect(n.kind, NotificationKind.unknown);
    });

    test('missing fields default honestly (unread defaults true)', () {
      final n = AppNotification.fromJson(const {});
      expect(n.id, '');
      expect(n.title, '');
      expect(n.unread, isTrue);
      expect(n.targetId, '');
    });
  });

  group('RegionsData.fromJson', () {
    test('decodes regions and districts, district region_id included', () {
      final data = RegionsData.fromJson({
        'regions': [
          {'id': 1, 'name': 'Toshkent shahri'},
        ],
        'districts': [
          {'id': 10, 'region_id': 1, 'name': 'Yunusabad'},
        ],
      });

      expect(data.regions, hasLength(1));
      expect(data.regions.single.id, 1);
      expect(data.regions.single.name, 'Toshkent shahri');
      expect(data.districts.single.regionId, 1);
      expect(data.districts.single.name, 'Yunusabad');
    });

    test('an unmatched regionId response (empty arrays) decodes cleanly', () {
      final data = RegionsData.fromJson({'regions': [], 'districts': []});
      expect(data.regions, isEmpty);
      expect(data.districts, isEmpty);
    });
  });

  group('AgentReviewPage.fromJson', () {
    test('decodes reviews newest-first with author and nextCursor', () {
      final page = AgentReviewPage.fromJson({
        'reviews': [
          {
            'id': 'review-1',
            'rating': 5,
            'comment': 'Great agent',
            'createdAt': {'seconds': 1700000000},
            'author': {
              'id': 'user-1',
              'fullName': 'Dilnoza Yusupova',
              'avatar': null,
            },
          },
        ],
        'nextCursor': 'review-1',
      });

      expect(page.reviews, hasLength(1));
      expect(page.reviews.single.rating, 5);
      expect(page.reviews.single.comment, 'Great agent');
      expect(page.reviews.single.author.fullName, 'Dilnoza Yusupova');
      expect(page.nextCursor, 'review-1');
    });

    test('a last page decodes nextCursor as null', () {
      final page = AgentReviewPage.fromJson(const {
        'reviews': <Map<String, dynamic>>[],
        'nextCursor': null,
      });
      expect(page.reviews, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });

  group('AdsSeries.fromJson', () {
    test('decodes granularity, from/to and zero-filled buckets', () {
      final series = AdsSeries.fromJson({
        'granularity': 'day',
        'from': {'seconds': 1700000000},
        'to': {'seconds': 1700086400},
        'buckets': [
          {
            'bucketStart': {'seconds': 1700000000},
            'adCreatedCount': 2,
            'adSoldCount': 0,
          },
        ],
      });

      expect(series.granularity, SeriesGranularity.day);
      expect(series.buckets, hasLength(1));
      expect(series.buckets.single.adCreatedCount, 2);
      expect(series.buckets.single.adSoldCount, 0);
    });

    test('an unrecognized granularity decodes to unknown', () {
      final series = AdsSeries.fromJson({
        'granularity': 'week',
        'from': {'seconds': 0},
        'to': {'seconds': 0},
        'buckets': <Map<String, dynamic>>[],
      });
      expect(series.granularity, SeriesGranularity.unknown);
    });
  });

  group('CoworkerSummary.fromJson', () {
    test('decodes counts and a present lastActiveAt', () {
      final summary = CoworkerSummary.fromJson({
        'coworkerId': 'coworker-1',
        'adsCreatedCount': 4,
        'adsSoldCount': 1,
        'leadsCreatedCount': 6,
        'lastActiveAt': {'seconds': 1700000000},
      });

      expect(summary.coworkerId, 'coworker-1');
      expect(summary.adsCreatedCount, 4);
      expect(
        summary.lastActiveAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
    });

    test(
      'a coworker with zero activity decodes lastActiveAt as null, not a fabricated timestamp',
      () {
        final summary = CoworkerSummary.fromJson({
          'coworkerId': 'coworker-2',
          'adsCreatedCount': 0,
          'adsSoldCount': 0,
          'leadsCreatedCount': 0,
          'lastActiveAt': null,
        });

        expect(summary.adsCreatedCount, 0);
        expect(summary.lastActiveAt, isNull);
      },
    );
  });

  group('AdPage.fromJson', () {
    test('decodes items and nextCursor', () {
      final page = AdPage.fromJson({
        'items': [
          {
            'id': 'ad-1',
            'title': 'Flat',
            'city': 'Tashkent',
            'district': 'Yunusabad',
            'type': 'residential',
            'category': 'sale',
            'price': 1000,
            'priceType': 'usd',
            'stage': '1',
            'nearPlacesList': <String>[],
            'active': true,
            'agentId': 'agent-1',
            'coworkerId': '',
            'photos': <String>[],
            'media': <Map<String, dynamic>>[],
            'createdAt': {'seconds': 0},
            'updatedAt': {'seconds': 0},
          },
        ],
        'nextCursor': 'cursor-abc',
      });

      expect(page.items, hasLength(1));
      expect(page.items.single.id, 'ad-1');
      expect(page.nextCursor, 'cursor-abc');
    });

    test('a last page decodes an empty item list and a null nextCursor', () {
      final page = AdPage.fromJson(const {
        'items': <Map<String, dynamic>>[],
        'nextCursor': null,
      });
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });

  group('AgentSummary/AgentDetail rating fields', () {
    test(
      'ratingAverage decodes as null (never 0.0) when the server omits it',
      () {
        final agent = AgentSummary.fromJson({
          'id': 'agent-1',
          'fullName': 'A',
          'email': 'a@example.com',
          'phoneNumber': null,
          'avatar': null,
          'adsCount': 3,
          // ratingAverage/ratingCount/address all omitted, as a
          // zero-review agent's payload would send them.
        });

        expect(agent.ratingAverage, isNull);
        expect(agent.ratingCount, 0);
        expect(agent.address, isNull);
      },
    );

    test('ratingAverage decodes a real average distinctly from null', () {
      final agent = AgentSummary.fromJson({
        'id': 'agent-2',
        'fullName': 'B',
        'email': 'b@example.com',
        'phoneNumber': null,
        'avatar': null,
        'adsCount': 3,
        'address': '12 Amir Temur St',
        'ratingAverage': 4.5,
        'ratingCount': 8,
      });

      expect(agent.ratingAverage, 4.5);
      expect(agent.ratingCount, 8);
      expect(agent.address, '12 Amir Temur St');
    });

    test('AgentDetail carries the same rating/address fields', () {
      final agent = AgentDetail.fromJson({
        'id': 'agent-3',
        'fullName': 'C',
        'email': 'c@example.com',
        'phoneNumber': null,
        'avatar': null,
        'adsCount': 3,
        'dealsClosedCount': 1,
        'ratingAverage': null,
        'ratingCount': 0,
      });

      expect(agent.ratingAverage, isNull);
      expect(agent.ratingCount, 0);
    });

    test(
      'AgentSummary can still be constructed positionally without the new fields '
      '(back-compat for pre-existing fixture call sites)',
      () {
        const agent = AgentSummary(
          id: 'agent-4',
          fullName: 'D',
          email: 'd@example.com',
          phoneNumber: null,
          avatar: null,
          adsCount: 0,
        );

        expect(agent.address, isNull);
        expect(agent.ratingAverage, isNull);
        expect(agent.ratingCount, 0);
      },
    );
  });
}
