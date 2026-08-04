// DioTransport tests — the real JSON-decode / error-mapping logic in
// lib/api/transport.dart, exercised through a fake HttpClientAdapter so
// nothing here ever touches a socket. Mirrors the four distinguishable
// failure kinds the task calls for: network failure, a well-formed 4xx/5xx
// error envelope, a non-enveloped error response, and a malformed
// (non-JSON) body — plus the request-shaping (method/url/query/headers)
// dio is handed.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

import 'support/fake_http_client_adapter.dart';

DioTransport buildTransport(FetchHandler handler) {
  final adapter = FakeHttpClientAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  return DioTransport(dio: dio);
}

void main() {
  group('DioTransport success paths', () {
    test('returns the decoded JSON body for a 2xx response', () async {
      final transport = buildTransport(
        (options) async =>
            ResponseBody.fromString(jsonEncode({'id': '1'}), 200),
      );

      final result = await transport.request(
        const TransportRequest(
          method: 'GET',
          url: 'https://api.example.com/ads/1',
        ),
      );

      expect(result, {'id': '1'});
    });

    test('returns null for an empty body (e.g. a 204 DELETE)', () async {
      final transport = buildTransport(
        (options) async => ResponseBody.fromString('', 204),
      );

      final result = await transport.request(
        const TransportRequest(
          method: 'DELETE',
          url: 'https://api.example.com/saved-ads/1',
        ),
      );

      expect(result, isNull);
    });

    test(
      'sends method, absolute url, headers, query and body to the adapter',
      () async {
        final adapter = FakeHttpClientAdapter(
          (options) async => ResponseBody.fromString(jsonEncode({}), 200),
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final transport = DioTransport(dio: dio);

        await transport.request(
          TransportRequest(
            method: 'POST',
            url: 'https://api.example.com/ads',
            query: const {'city': 'Tashkent', 'page': 2, 'missing': null},
            body: const {'title': 'New ad'},
            headers: const {'Authorization': 'Bearer abc'},
          ),
        );

        final sent = adapter.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.path, 'https://api.example.com/ads');
        expect(sent.queryParameters, {'city': 'Tashkent', 'page': 2});
        expect(sent.headers['Authorization'], 'Bearer abc');
        expect(sent.headers['Content-Type'], contains('application/json'));
      },
    );
  });

  group('DioTransport error mapping', () {
    test(
      'reconstructs ApiErrorException from a well-formed 4xx error envelope',
      () async {
        final transport = buildTransport(
          (options) async => ResponseBody.fromString(
            jsonEncode({
              'error': {'code': 'not_found', 'message': 'Ad not found'},
            }),
            404,
          ),
        );

        await expectLater(
          transport.request(
            const TransportRequest(
              method: 'GET',
              url: 'https://api.example.com/ads/x',
            ),
          ),
          throwsA(
            isA<ApiErrorException>()
                .having((e) => e.code, 'code', ApiErrorCode.notFound)
                .having((e) => e.message, 'message', 'Ad not found')
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.isClientError, 'isClientError', true)
                .having((e) => e.isServerError, 'isServerError', false),
          ),
        );
      },
    );

    test(
      'reconstructs ApiErrorException from a well-formed 5xx error envelope',
      () async {
        final transport = buildTransport(
          (options) async => ResponseBody.fromString(
            jsonEncode({
              'error': {'code': 'internal', 'message': 'Internal server error'},
            }),
            500,
          ),
        );

        await expectLater(
          transport.request(
            const TransportRequest(
              method: 'GET',
              url: 'https://api.example.com/ads',
            ),
          ),
          throwsA(
            isA<ApiErrorException>()
                .having((e) => e.code, 'code', ApiErrorCode.internal)
                .having((e) => e.isServerError, 'isServerError', true)
                .having((e) => e.isClientError, 'isClientError', false),
          ),
        );
      },
    );

    test(
      'falls back to a generic ApiErrorException for a non-enveloped error response',
      () async {
        final transport = buildTransport(
          (options) async => ResponseBody.fromString(
            jsonEncode({'oops': true}),
            502,
            statusMessage: 'Bad Gateway',
          ),
        );

        await expectLater(
          transport.request(
            const TransportRequest(
              method: 'GET',
              url: 'https://api.example.com/ads',
            ),
          ),
          throwsA(
            isA<ApiErrorException>()
                .having((e) => e.code, 'code', ApiErrorCode.unknown)
                .having((e) => e.statusCode, 'statusCode', 502)
                .having((e) => e.message, 'message', 'Bad Gateway'),
          ),
        );
      },
    );

    test(
      'throws MalformedResponseException for a non-JSON body on a non-2xx response',
      () async {
        final transport = buildTransport(
          (options) async =>
              ResponseBody.fromString('<html>gateway error</html>', 502),
        );

        await expectLater(
          transport.request(
            const TransportRequest(
              method: 'GET',
              url: 'https://api.example.com/ads',
            ),
          ),
          throwsA(
            isA<MalformedResponseException>().having(
              (e) => e.statusCode,
              'statusCode',
              502,
            ),
          ),
        );
      },
    );

    test(
      'throws MalformedResponseException for a non-JSON body even on a 2xx response',
      () async {
        final transport = buildTransport(
          (options) async => ResponseBody.fromString('not json at all', 200),
        );

        await expectLater(
          transport.request(
            const TransportRequest(
              method: 'GET',
              url: 'https://api.example.com/ads',
            ),
          ),
          throwsA(
            isA<MalformedResponseException>().having(
              (e) => e.statusCode,
              'statusCode',
              200,
            ),
          ),
        );
      },
    );

    test('throws NetworkException when no response is ever received', () async {
      final adapter = FakeHttpClientAdapter(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final transport = DioTransport(dio: dio);

      await expectLater(
        transport.request(
          const TransportRequest(
            method: 'GET',
            url: 'https://api.example.com/ads',
          ),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
