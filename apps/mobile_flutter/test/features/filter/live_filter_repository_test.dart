// `LiveFilterRepository` — the wire contract behind the filter sheet's
// "Apply Filters (N)" preview.
//
// These assert the *shape of the request*, not just the returned number,
// because the number was never the bug: `countMatching` used to call
// `AdsResource.list(filters: …)` and return `.length`, which is the correct
// answer obtained by downloading every matching ad — fully serialized,
// photo URLs and all — once on sheet open and again after every debounced
// field edit. Against that old implementation each test here fails twice
// over: no `countOnly` param goes out, and the `{ "count": N }` body the
// server answers a count request with is not a JSON array, so the decode
// throws before any expectation is even reached.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/data/live_filter_repository.dart';

import '../../api/support/fake_transport.dart';

LaCasaApi buildApi(FakeTransport transport) {
  return LaCasaApi(
    ApiClient(
      transport: transport,
      tokenStorage: InMemoryTokenStorage(),
      baseUrl: 'https://api.example.com',
    ),
  );
}

void main() {
  group('LiveFilterRepository.countMatching', () {
    test('asks the server to count, and never downloads the rows', () async {
      final transport = FakeTransport((req) async => {'count': 7});
      final repo = LiveFilterRepository(buildApi(transport));

      final count = await repo.countMatching(const AdFilters());

      expect(count, 7);
      final request = transport.requests.single;
      expect(request.method, 'GET');
      expect(request.url, 'https://api.example.com/ads');
      // The whole point: the count branch, not the bare-array branch.
      expect(request.query!['countOnly'], 'true');
    });

    test(
      'every filter still travels as a query param — the narrowing is the '
      'server\'s, only the response shape changed',
      () async {
        final transport = FakeTransport((req) async => {'count': 2});
        final repo = LiveFilterRepository(buildApi(transport));

        await repo.countMatching(
          const AdFilters(
            city: 'Tashkent',
            district: 'Chilonzor',
            category: AdCategory.sale,
            type: AdType.residential,
            rooms: 3,
            repairment: Repairment.excellent,
            storey: 5,
            furniture: Furniture.withFurniture,
            areaMin: 40,
            areaMax: 120,
            priceMin: 100000,
            priceMax: 1000000,
            q: 'sunny',
          ),
        );

        final query = transport.requests.single.query!;
        expect(query['city'], 'Tashkent');
        expect(query['district'], 'Chilonzor');
        expect(query['category'], 'sale');
        expect(query['type'], 'residential');
        expect(query['rooms'], 3);
        expect(query['repairment'], 'excellent');
        expect(query['storey'], 5);
        expect(query['furniture'], 'withFurniture');
        expect(query['areaMin'], 40);
        expect(query['areaMax'], 120);
        expect(query['priceMin'], 100000);
        expect(query['priceMax'], 1000000);
        expect(query['q'], 'sunny');
        expect(query['countOnly'], 'true');
      },
    );

    test(
      'sends no sort/limit/cursor/paged — a count is order- and '
      'page-independent',
      () async {
        final transport = FakeTransport((req) async => {'count': 0});
        final repo = LiveFilterRepository(buildApi(transport));

        await repo.countMatching(const AdFilters());

        final query = transport.requests.single.query!;
        expect(query['sort'], isNull);
        expect(query['limit'], isNull);
        expect(query['cursor'], isNull);
        expect(query['paged'], isNull);
      },
    );

    test('zero matches is a normal result, not an error', () async {
      final transport = FakeTransport((req) async => {'count': 0});
      final repo = LiveFilterRepository(buildApi(transport));

      expect(await repo.countMatching(const AdFilters(rooms: 9)), 0);
    });

    test('a transport failure still surfaces as an ApiException', () async {
      final transport = FakeTransport(
        (req) async => throw const NetworkException('offline'),
      );
      final repo = LiveFilterRepository(buildApi(transport));

      await expectLater(
        repo.countMatching(const AdFilters()),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
