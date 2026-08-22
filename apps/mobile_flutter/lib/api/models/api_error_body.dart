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
  // The `POST /publish/ads/:adId/:channel/retry` error-code set
  // (`apps/api/src/services/publishService.js#retryPublish`). Kept as
  // distinct members rather than folded into existing ones (`notFound`,
  // `validation`, ...) because each names a genuinely different situation a
  // caller needs to branch on — see `resources/publish_resource.dart#retry`'s
  // doc comment for what each one means to the user.
  notRetryable, // 400 — :channel has no server-side call to replay
  notFailed, // 400 — nothing to retry; use the normal publish endpoint
  alreadyPublished, // 409 — retrying would double-post
  awaitingReview, // 409 — a human may still be mid-review
  retryUnavailable, // 409 — a FAILED row predating retry support
  retryInProgress, // 409 — a concurrent retry already claimed this row
  adNotFound, // 404 — retry's own ownership-check 404, distinct from `notFound`
  // `POST /coworkers` (`apps/api/src/routes/coworkers.js`) — 403 for a SOLO
  // realtor. `add_coworker_screen.dart` pre-empts this client-side by
  // reading `session.user?.realtor?.kind` before ever showing the form, so
  // in practice this only fires on a stale/racing client; kept as its own
  // member (rather than falling through to `forbidden`) so that defensive
  // path can still branch on it precisely, matching `coworkers_resource.dart`'s
  // doc comment for this code.
  soloRealtor,
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
    'not_retryable' => ApiErrorCode.notRetryable,
    'not_failed' => ApiErrorCode.notFailed,
    'already_published' => ApiErrorCode.alreadyPublished,
    'awaiting_review' => ApiErrorCode.awaitingReview,
    'retry_unavailable' => ApiErrorCode.retryUnavailable,
    'retry_in_progress' => ApiErrorCode.retryInProgress,
    'ad_not_found' => ApiErrorCode.adNotFound,
    'solo_realtor' => ApiErrorCode.soloRealtor,
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
