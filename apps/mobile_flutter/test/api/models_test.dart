// Wire-shape decoding tests for every model in lib/api/models/ — full
// payloads, the null/missing-field case, and an unknown-server-enum case
// per model, per the task's coverage requirement.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/api/models/wire_timestamp.dart';

import 'support/fixtures.dart';

void main() {
  group('Ad.fromJson', () {
    test('decodes a full ad payload', () {
      final ad = Ad.fromJson(fullAdJson());

      expect(ad.id, 'ad-1');
      expect(ad.title, 'Sunny 2-room flat');
      expect(ad.type, AdType.residential);
      expect(ad.category, AdCategory.sale);
      expect(ad.repairment, Repairment.good);
      expect(ad.furniture, Furniture.withFurniture);
      expect(ad.stage, AdStage.active);
      expect(ad.priceType, CurrencyCode.usd);
      expect(ad.rooms, 2);
      expect(ad.area, 54.5);
      expect(ad.price, 100000);
      expect(ad.nearPlacesList, ['metro', 'school']);
      expect(ad.active, true);
      expect(ad.lat, 41.31);
      expect(ad.lng, 69.28);
      expect(ad.hasPin, true);
      expect(ad.tour3dLink, 'https://tour.example.com/ad-1');
      expect(ad.coworkerId, '');
      expect(ad.photos, ['https://cdn.example.com/1.jpg']);
      expect(ad.media, hasLength(1));
      expect(ad.media.single.mediaType, AdMediaType.photo);
      expect(ad.media.single.position, 0);
      expect(
        ad.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
      expect(
        ad.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000100000, isUtc: true),
      );
      expect(ad.pricePerSqm, (100000 / 54.5).round());
    });

    test(
      'treats omitted repairment/furniture/nullable fields as null, not a decode error',
      () {
        final json = fullAdJson(repairment: null, furniture: null)
          ..remove('address')
          ..remove('reference')
          ..remove('hashtags')
          ..remove('description')
          ..['lat'] = null
          ..['lng'] = null
          ..['rooms'] = null
          ..['area'] = null
          ..['storey'] = null
          ..['floors'] = null;

        final ad = Ad.fromJson(json);

        expect(ad.repairment, isNull);
        expect(ad.furniture, isNull);
        expect(ad.address, isNull);
        expect(ad.reference, isNull);
        expect(ad.hashtags, isNull);
        expect(ad.description, isNull);
        expect(ad.lat, isNull);
        expect(ad.lng, isNull);
        expect(ad.hasPin, false);
        expect(ad.rooms, isNull);
        expect(ad.area, isNull);
        // area is null -> pricePerSqm must be null, never a divide-by-null crash.
        expect(ad.pricePerSqm, isNull);
      },
    );

    test(
      'falls back to .unknown for an enum value the server added after this client shipped',
      () {
        final ad = Ad.fromJson(
          fullAdJson(
            type: 'commercial',
            category: 'lease',
            stage: '9',
            repairment: 'pristine',
            furniture: 'partial',
          ),
        );

        expect(ad.type, AdType.unknown);
        expect(ad.category, AdCategory.unknown);
        expect(ad.stage, AdStage.unknown);
        expect(ad.repairment, Repairment.unknown);
        expect(ad.furniture, Furniture.unknown);
      },
    );

    test(
      'pricePerSqm is null for a zero-or-negative area, not Infinity or a crash',
      () {
        expect(computePricePerSqm(100, 0), isNull);
        expect(computePricePerSqm(100, -5), isNull);
      },
    );
  });

  group('dateTimeFromWireTimestamp', () {
    test('reads the legacy {seconds} shape, not an ISO string', () {
      final dt = dateTimeFromWireTimestamp({'seconds': 1000});
      expect(dt, DateTime.fromMillisecondsSinceEpoch(1000000, isUtc: true));
    });
  });

  group('SavedAd.fromJson', () {
    test('decodes the full Ad shape plus saved:true', () {
      final json = {...fullAdJson(), 'saved': true};
      final savedAd = SavedAd.fromJson(json);

      expect(savedAd.saved, true);
      expect(savedAd.ad.id, 'ad-1');
      expect(savedAd.ad.type, AdType.residential);
    });

    test('defaults saved to true when the server omits it', () {
      final savedAd = SavedAd.fromJson(fullAdJson());
      expect(savedAd.saved, true);
    });
  });

  group('AgentSummary.fromJson', () {
    test('decodes a full row', () {
      final agent = AgentSummary.fromJson({
        'id': 'agent-1',
        'fullName': 'Aziz Karimov',
        'email': 'aziz@example.com',
        'phoneNumber': '+998901234567',
        'avatar': 'https://cdn.example.com/avatar.jpg',
        'adsCount': 12,
      });

      expect(agent.id, 'agent-1');
      expect(agent.phoneNumber, '+998901234567');
      expect(agent.adsCount, 12);
    });

    test('treats a missing phoneNumber/avatar as null, not a throw', () {
      final agent = AgentSummary.fromJson({
        'id': 'agent-1',
        'fullName': 'Aziz Karimov',
        'email': 'aziz@example.com',
        'phoneNumber': null,
        'avatar': null,
        'adsCount': 0,
      });

      expect(agent.phoneNumber, isNull);
      expect(agent.avatar, isNull);
    });
  });

  group('AgentDetail.fromJson', () {
    test('decodes adsCount and dealsClosedCount independently', () {
      final agent = AgentDetail.fromJson({
        'id': 'agent-1',
        'fullName': 'Aziz Karimov',
        'email': 'aziz@example.com',
        'phoneNumber': null,
        'avatar': null,
        'adsCount': 12,
        'dealsClosedCount': 3,
      });

      expect(agent.adsCount, 12);
      expect(agent.dealsClosedCount, 3);
    });
  });

  group('AuthUser.fromJson', () {
    Map<String, dynamic> baseUser({
      String role = 'user',
      Map<String, dynamic>? realtor,
    }) => {
      'id': 'user-1',
      'fullName': 'Dilnoza Yusupova',
      'email': 'dilnoza@example.com',
      'role': role,
      'phoneNumber': '+998901112233',
      'avatar': null,
      'agentId': null,
      'tgChatIds': [123456789, 987654321],
      'igAccounts': [
        {
          'igUserId': 'ig-1',
          'username': 'dilnoza',
          'expiresAt': '2027-01-01T00:00:00.000Z',
        },
      ],
      'igAssistConsentAt': '2026-01-01T00:00:00.000Z',
      'realtor': realtor,
    };

    test('decodes a full agent user with a realtor profile', () {
      final user = AuthUser.fromJson(
        baseUser(
          role: 'agent',
          realtor: {
            'kind': 'agency',
            'status': 'approved',
            'agencyName': 'La Casa Realty',
            'officePhone': '+998712345678',
            'teamSize': 'two_to_five',
            'appliedAt': '2025-06-01T00:00:00.000Z',
            'decidedAt': '2025-06-05T00:00:00.000Z',
          },
        ),
      );

      expect(user.role, UserRole.agent);
      expect(user.tgChatIds, [123456789, 987654321]);
      expect(user.igAccounts, hasLength(1));
      expect(user.igAccounts.single.username, 'dilnoza');
      expect(user.realtor, isNotNull);
      expect(user.realtor!.kind, RealtorKind.agency);
      expect(user.realtor!.status, RealtorStatus.approved);
      expect(user.realtor!.teamSize, TeamSize.twoToFive);
    });

    test(
      'treats a null realtor (buyer/coworker) and empty igAccounts/tgChatIds as valid, not missing data',
      () {
        final json = baseUser()
          ..['tgChatIds'] = <int>[]
          ..['igAccounts'] = <Map<String, dynamic>>[];
        final user = AuthUser.fromJson(json);

        expect(user.realtor, isNull);
        expect(user.tgChatIds, isEmpty);
        expect(user.igAccounts, isEmpty);
        expect(user.agentId, isNull);
      },
    );

    test(
      'falls back to .unknown for a role/realtor enum the client has never seen',
      () {
        final user = AuthUser.fromJson(
          baseUser(
            role: 'superadmin',
            realtor: {
              'kind': 'franchise',
              'status': 'under_review',
              'agencyName': null,
              'officePhone': null,
              'teamSize': 'huge',
              'appliedAt': null,
              'decidedAt': null,
            },
          ),
        );

        expect(user.role, UserRole.unknown);
        expect(user.realtor!.kind, RealtorKind.unknown);
        expect(user.realtor!.status, RealtorStatus.unknown);
        expect(user.realtor!.teamSize, TeamSize.unknown);
      },
    );
  });

  group('ApiErrorBody.fromJson', () {
    test('decodes a known error code', () {
      final body = ApiErrorBody.fromJson({
        'code': 'not_found',
        'message': 'Ad not found',
      });
      expect(body.code, ApiErrorCode.notFound);
      expect(body.message, 'Ad not found');
    });

    test('falls back to .unknown for an error code this client predates', () {
      final body = ApiErrorBody.fromJson({
        'code': 'rate_limited',
        'message': 'Slow down',
      });
      expect(body.code, ApiErrorCode.unknown);
      expect(body.message, 'Slow down');
    });
  });
}
