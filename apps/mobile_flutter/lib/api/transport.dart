/// The raw-HTTP half of the client, mirroring
/// `apps/mobile/src/lib/httpTransport.ts#fetchTransport`'s contract:
/// build a URL (base URL already applied by [ApiClient], query params
/// appended here), send the request, decode a JSON body, and turn a
/// non-2xx response into a typed [ApiErrorException] reconstructed from the
/// `{ error: { code, message } }` envelope when the body is shaped that
/// way — falling back to a generic one when it isn't (an HTML error page
/// from a proxy in front of the API, e.g.).
///
/// Built on `dio` with `validateStatus` forced to always-true: unlike
/// `fetch`, dio's default behaviour is to *throw* for a non-2xx response,
/// which would make the error body unreachable for decoding. Forcing dio to
/// hand back every response regardless of status re-creates the
/// `fetch`-style "check `response.ok` yourself" flow the reference
/// TypeScript transport relies on.
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'models/api_error_body.dart';

typedef QueryParams = Map<String, Object?>;

/// A single outbound HTTP call, already resolved to an absolute URL (base
/// URL + path already joined by [ApiClient]).
class TransportRequest {
  final String method;
  final String url;
  final QueryParams? query;

  /// A JSON-encodable value (`Map`/`List`/primitive), or `null` for a
  /// bodyless request.
  final Object? body;
  final Map<String, String>? headers;

  const TransportRequest({
    required this.method,
    required this.url,
    this.query,
    this.body,
    this.headers,
  });
}

/// The one thing every environment must supply: a function that turns a
/// [TransportRequest] into a decoded JSON response body (a `Map`, `List`,
/// primitive, or `null` for an empty body), or throws one of
/// [ApiException]'s subtypes for anything that isn't a clean 2xx JSON
/// response.
abstract class Transport {
  Future<Object?> request(TransportRequest req);
}

/// Backed by `dio`.
class DioTransport implements Transport {
  final Dio _dio;

  DioTransport({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.responseType = ResponseType.plain;
    // Never let dio throw for a non-2xx response — see the file doc
    // comment. Every other failure mode (no response at all: timeouts,
    // connection errors, DNS failures, cancellation) still throws a
    // DioException, which request() below maps to NetworkException.
    _dio.options.validateStatus = (_) => true;
  }

  @override
  Future<Object?> request(TransportRequest req) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        req.url,
        data: req.body,
        queryParameters: _cleanQuery(req.query),
        options: Options(
          method: req.method,
          headers: {'Content-Type': 'application/json', ...?req.headers},
        ),
      );
    } on DioException catch (e) {
      throw NetworkException(_networkMessage(e), cause: e);
    }

    final statusCode = response.statusCode ?? 0;
    final raw = response.data;
    final text = raw is String ? raw : (raw == null ? '' : raw.toString());

    Object? data;
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
      } on FormatException catch (e) {
        throw MalformedResponseException(
          'Response body was not valid JSON',
          statusCode: statusCode,
          cause: e,
        );
      }
    }

    if (statusCode < 200 || statusCode >= 300) {
      if (data is Map<String, dynamic> && _isApiErrorBody(data)) {
        throw ApiErrorException(
          body: ApiErrorBody.fromJson(data['error'] as Map<String, dynamic>),
          statusCode: statusCode,
        );
      }
      throw ApiErrorException(
        body: ApiErrorBody(
          code: ApiErrorCode.unknown,
          message: response.statusMessage?.isNotEmpty == true
              ? response.statusMessage!
              : 'Request failed',
        ),
        statusCode: statusCode,
      );
    }

    return data;
  }
}

QueryParams? _cleanQuery(QueryParams? query) {
  if (query == null) return null;
  final cleaned = <String, Object?>{};
  for (final entry in query.entries) {
    if (entry.value == null) continue;
    cleaned[entry.key] = entry.value;
  }
  return cleaned.isEmpty ? null : cleaned;
}

bool _isApiErrorBody(Map<String, dynamic> value) {
  final error = value['error'];
  return error is Map<String, dynamic> && error['code'] is String;
}

String _networkMessage(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => 'The request timed out',
    DioExceptionType.connectionError => 'Could not connect to the server',
    DioExceptionType.cancel => 'The request was cancelled',
    _ => e.message ?? 'A network error occurred',
  };
}
