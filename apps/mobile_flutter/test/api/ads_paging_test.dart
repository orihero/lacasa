// AdsResource/AgentAdsResource's paging additions — proves the bare-array
// and paged-envelope shapes stay statically distinct (list()/myList() never
// send paging params and always decode a List<Ad>; listPage()/myListPage()
// always send paged=true and always decode an AdPage), plus the new q/sort/
// stage query params.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

import 'support/fake_transport.dart';
import 'support/fixtures.dart';

ApiClient buildClient(FakeTransport transport) {
  return ApiClient(
    transport: transport,
    tokenStorage: InMemoryTokenStorage(),
    baseUrl: 'https://api.example.com',
  );
}

void main() {
  group('AdsResource.list (bare)', () {
    test('never sends limit/cursor/paged, decodes a bare List<Ad>', () async {
      final transport = FakeTransport((req) async => [fullAdJson()]);
      final ads = AdsResource(buildClient(transport));

      final result = await ads.list();

      final query = transport.requests.single.query!;
      expect(query['limit'], isNull);
      expect(query['cursor'], isNull);
      expect(query['paged'], isNull);
      expect(result, isA<List<Ad>>());
      expect(result, hasLength(1));
    });

    test('q and a real sort value are forwarded', () async {
      final transport = FakeTransport((req) async => <Map<String, dynamic>>[]);
      final ads = AdsResource(buildClient(transport));

      await ads.list(
        filters: const AdFilters(q: 'sunny flat'),
        sort: AdListSort.priceDesc,
      );

      final query = transport.requests.single.query!;
      expect(query['q'], 'sunny flat');
      expect(query['sort'], 'priceDesc');
    });

    test('the default sort (newest) sends no sort param at all', () async {
      final transport = FakeTransport((req) async => <Map<String, dynamic>>[]);
      final ads = AdsResource(buildClient(transport));

      await ads.list();

      expect(transport.requests.single.query!['sort'], isNull);
    });
  });

  group('AdsResource.listPage', () {
    test(
      'always sends paged=true, even with no limit/cursor given, and decodes an AdPage',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'items': [fullAdJson()],
            'nextCursor': 'cursor-1',
          },
        );
        final ads = AdsResource(buildClient(transport));

        final page = await ads.listPage();

        expect(transport.requests.single.query!['paged'], 'true');
        expect(page, isA<AdPage>());
        expect(page.items, hasLength(1));
        expect(page.nextCursor, 'cursor-1');
      },
    );

    test('forwards limit/cursor', () async {
      final transport = FakeTransport(
        (req) async => {'items': <Map<String, dynamic>>[], 'nextCursor': null},
      );
      final ads = AdsResource(buildClient(transport));

      await ads.listPage(limit: 50, cursor: 'cursor-0');

      final query = transport.requests.single.query!;
      expect(query['limit'], 50);
      expect(query['cursor'], 'cursor-0');
    });
  });

  group('AgentAdsResource.myList (bare)', () {
    test('never sends limit/cursor/paged, decodes a bare List<Ad>', () async {
      final transport = FakeTransport((req) async => [fullAdJson()]);
      final agentAds = AgentAdsResource(buildClient(transport));

      final result = await agentAds.myList();

      final query = transport.requests.single.query!;
      expect(query['limit'], isNull);
      expect(query['cursor'], isNull);
      expect(query['paged'], isNull);
      expect(result, isA<List<Ad>>());
    });

    test('stage is forwarded as its "1"/"2"/"3" wire value', () async {
      final transport = FakeTransport((req) async => <Map<String, dynamic>>[]);
      final agentAds = AgentAdsResource(buildClient(transport));

      await agentAds.myList(stage: AdStage.sold);

      expect(transport.requests.single.query!['stage'], '2');
    });

    test('a null stage sends no stage param', () async {
      final transport = FakeTransport((req) async => <Map<String, dynamic>>[]);
      final agentAds = AgentAdsResource(buildClient(transport));

      await agentAds.myList();

      expect(transport.requests.single.query!['stage'], isNull);
    });

    test(
      'the legacy AdSort values still send their historical wire strings',
      () async {
        final transport = FakeTransport(
          (req) async => <Map<String, dynamic>>[],
        );
        final agentAds = AgentAdsResource(buildClient(transport));

        await agentAds.myList(sort: AdSort.highestPrice);

        expect(transport.requests.single.query!['sort'], 'highestPrice');
      },
    );
  });

  group('AgentAdsResource.myListPage', () {
    test('always sends paged=true and decodes an AdPage', () async {
      final transport = FakeTransport(
        (req) async => {
          'items': [fullAdJson(stage: '2')],
          'nextCursor': null,
        },
      );
      final agentAds = AgentAdsResource(buildClient(transport));

      final page = await agentAds.myListPage(
        stage: AdStage.sold,
        sort: AdListSort.oldest,
      );

      final query = transport.requests.single.query!;
      expect(query['paged'], 'true');
      expect(query['stage'], '2');
      expect(query['sort'], 'oldest');
      expect(page, isA<AdPage>());
      expect(page.items.single.stage, AdStage.sold);
      expect(page.nextCursor, isNull);
    });
  });
}
