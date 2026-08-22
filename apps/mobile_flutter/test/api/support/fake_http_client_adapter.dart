/// A hand-rolled `dio` [HttpClientAdapter] for [DioTransport] tests — lets
/// `transport_test.dart` exercise the real JSON-decode / error-mapping
/// logic in `lib/api/transport.dart` without ever touching a socket.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FetchHandler = Future<ResponseBody> Function(RequestOptions options);

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this._handler);

  final FetchHandler _handler;

  /// The most recent request the adapter was asked to fetch — lets tests
  /// assert on method/url/headers/query/body without a mocking framework.
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    lastRequest = options;
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
