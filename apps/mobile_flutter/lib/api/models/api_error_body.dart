/// The `{ code, message }` object nested under `error` in every non-2xx
/// La Casa API response: `{ "error": { "code": string, "message": string } }`.
library;

/// Every `error.code` value the live API can send, collected from
/// `apps/api/src/{index.js,middleware/*.js,routes/*.js}`'s
/// `res.status(...).json({ error: { code, message } })` call sites. `unknown`
/// is this client's own fallback for any code the server adds later — never
/// a value the server sends.
enum ApiErrorCode {
  validation,
  unauthorized,
  forbidden,
  notFound,
  emailTaken,
  invalidCredentials,
  noConnectedAccounts,
  unknownChannel,
  consentRequired,
  llmUnconfigured,
  llmRefusal,
  llmEmpty,
  dailyCap,
  notADraft,
  // The three `POST /api/contact` codes (`apps/api/src/routes/contact.js`).
  // Added when that route gained a client (`resources/contact_resource.dart`)
  // — before that they existed server-side but nothing here could branch on
  // them, so they fell through to `unknown` like any unrecognized code.
  rateLimited,
  contactUnconfigured,
  contactRelayFailed,
  internal,
  unknown;

  static ApiErrorCode fromWire(String? value) => switch (value) {
    'validation' => ApiErrorCode.validation,
    'unauthorized' => ApiErrorCode.unauthorized,
    'forbidden' => ApiErrorCode.forbidden,
    'not_found' => ApiErrorCode.notFound,
    'email_taken' => ApiErrorCode.emailTaken,
    'invalid_credentials' => ApiErrorCode.invalidCredentials,
    'no_connected_accounts' => ApiErrorCode.noConnectedAccounts,
    'unknown_channel' => ApiErrorCode.unknownChannel,
    'consent_required' => ApiErrorCode.consentRequired,
    'llm_unconfigured' => ApiErrorCode.llmUnconfigured,
    'llm_refusal' => ApiErrorCode.llmRefusal,
    'llm_empty' => ApiErrorCode.llmEmpty,
    'daily_cap' => ApiErrorCode.dailyCap,
    'not_a_draft' => ApiErrorCode.notADraft,
    'rate_limited' => ApiErrorCode.rateLimited,
    'contact_unconfigured' => ApiErrorCode.contactUnconfigured,
    'contact_relay_failed' => ApiErrorCode.contactRelayFailed,
    'internal' => ApiErrorCode.internal,
    _ => ApiErrorCode.unknown,
  };
}

class ApiErrorBody {
  final ApiErrorCode code;
  final String message;

  const ApiErrorBody({required this.code, required this.message});

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      code: ApiErrorCode.fromWire(json['code'] as String?),
      message: json['message'] as String? ?? 'Request failed',
    );
  }
}
