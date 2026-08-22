/// Wires an injected [Transport] + [TokenStorage] into the one method every
/// resource class (`lib/api/resources/*.dart`) calls — mirrors
/// `@lacasa/api-client`'s `core/client.ts#createApiClient` exactly,
/// including the "await the token before building headers" ordering: a
/// [TokenStorage] backed by something slow (a cold keystore/keychain read
/// at launch) can never race a request out the door without its token
/// attached.
library;

import 'token_storage.dart';
import 'transport.dart';

class ApiClient {
  final Transport transport;
  final TokenStorage tokenStorage;

  /// Prepended verbatim to every request's `path` (e.g.
  /// `"http://localhost:4200/api"`).
  final String baseUrl;

  const ApiClient({
    required this.transport,
    required this.tokenStorage,
    required this.baseUrl,
  });

  /// Issues one request and returns the decoded JSON body (a `Map`, `List`,
  /// primitive, or `null`). Resource classes are responsible for casting
  /// and mapping that into their own model types — see
  /// `lib/api/resources/*.dart`.
  Future<Object?> request({
    required String method,
    required String path,
    QueryParams? query,
    Object? body,
  }) async {
    final token = await tokenStorage.getToken();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return transport.request(
      TransportRequest(
        method: method,
        url: '$baseUrl$path',
        query: query,
        body: body,
        headers: headers,
      ),
    );
  }
}
