/// Typed failures a [Transport]/[ApiClient] call can throw. Every request
/// rejects with exactly one of these — never a bare [Exception] — so a
/// caller can branch on what actually went wrong:
///
///  - [NetworkException]: no HTTP response was ever received (offline, DNS
///    failure, connection refused, timeout, request cancelled).
///  - [ApiErrorException]: an HTTP response WAS received and its status was
///    outside 2xx. Carries the response status plus the decoded
///    `{ code, message }` error body when the server sent one in the
///    uniform envelope every route uses (`lib/api/models/api_error_body.dart`);
///    falls back to [ApiErrorCode.unknown]/[ApiErrorCode.internal]-shaped
///    body with the HTTP reason phrase when it didn't. [isClientError]/
///    [isServerError] distinguish 4xx from 5xx without needing separate
///    exception types for what is, on the wire, the same envelope.
///  - [MalformedResponseException]: an HTTP response was received but its
///    body could not be parsed as JSON at all (a proxy's HTML error page,
///    a truncated body, etc.) — distinct from [ApiErrorException]'s
///    "valid JSON, just not the error envelope shape" fallback.
library;

import 'models/api_error_body.dart';

sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// No response reached the client at all.
class NetworkException extends ApiException {
  /// The underlying platform exception (a `DioException`, typically),
  /// preserved for logging — never required for callers to branch on.
  final Object? cause;

  const NetworkException(super.message, {this.cause});

  @override
  String toString() => 'NetworkException: $message';
}

/// A non-2xx HTTP response, decoded into the API's uniform error envelope
/// where possible.
class ApiErrorException extends ApiException {
  final ApiErrorBody body;
  final int statusCode;

  ApiErrorException({required this.body, required this.statusCode})
    : super(body.message);

  ApiErrorCode get code => body.code;

  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => 'ApiErrorException(${code.name}, $statusCode): $message';
}

/// A response (2xx or not) whose body could not be parsed as JSON.
class MalformedResponseException extends ApiException {
  final int? statusCode;
  final Object? cause;

  const MalformedResponseException(
    super.message, {
    this.statusCode,
    this.cause,
  });

  @override
  String toString() => 'MalformedResponseException($statusCode): $message';
}
