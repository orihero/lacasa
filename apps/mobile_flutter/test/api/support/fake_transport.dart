/// A fake [Transport] for resource/[ApiClient] tests — returns canned data
/// (or throws a canned [ApiException]) instead of making any real HTTP
/// call, and records every request it was asked to make so tests can
/// assert on method/url/query/body/headers.
library;

import 'package:lacasa_mobile/api/transport.dart';

class FakeTransport implements Transport {
  FakeTransport(this._handler);

  final Future<Object?> Function(TransportRequest req) _handler;
  final List<TransportRequest> requests = [];

  @override
  Future<Object?> request(TransportRequest req) {
    requests.add(req);
    return _handler(req);
  }
}
