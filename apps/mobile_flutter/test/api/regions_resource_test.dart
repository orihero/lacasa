// RegionsResource — correct method/path/query shaping and correct
// decoding, against a FakeTransport (no live network).

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

import 'support/fake_transport.dart';

ApiClient buildClient(FakeTransport transport) {
  return ApiClient(
    transport: transport,
    tokenStorage: InMemoryTokenStorage(),
    baseUrl: 'https://api.example.com',
  );
}

void main() {
  group('RegionsResource', () {
    test(
      'fetch GETs /regions with no query when regionId is omitted',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'regions': [
              {'id': 1, 'name': 'Toshkent shahri'},
            ],
            'districts': [
              {'id': 10, 'region_id': 1, 'name': 'Yunusabad'},
            ],
          },
        );
        final regions = RegionsResource(buildClient(transport));

        final result = await regions.fetch();

        expect(transport.requests.single.method, 'GET');
        expect(
          transport.requests.single.url,
          'https://api.example.com/regions',
        );
        expect(transport.requests.single.query!['regionId'], isNull);
        expect(result.regions, hasLength(1));
        expect(result.districts.single.regionId, 1);
      },
    );

    test('fetch(regionId:) narrows both arrays via the same parser', () async {
      final transport = FakeTransport(
        (req) async => {
          'regions': <Map<String, dynamic>>[],
          'districts': <Map<String, dynamic>>[],
        },
      );
      final regions = RegionsResource(buildClient(transport));

      final result = await regions.fetch(regionId: 999);

      expect(transport.requests.single.query!['regionId'], 999);
      // A non-matching regionId is a 200 with empty arrays, not a throw.
      expect(result.regions, isEmpty);
      expect(result.districts, isEmpty);
    });
  });
}
