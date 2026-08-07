// Every `error.code` value the API currently returns, collected from
// apps/api/src/{index.js,middleware/*.js,routes/*.js}'s
// `res.status(...).json({ error: { code, message } })` call sites.
export const ERROR_CODES = [
  'validation',
  'unauthorized',
  'forbidden',
  'not_found',
  'email_taken',
  'invalid_credentials',
  'no_connected_accounts',
  'unknown_channel',
  'consent_required',
  'llm_unconfigured',
  'llm_refusal',
  'llm_empty',
  'daily_cap',
  'not_a_draft',
  'internal',
] as const;

export type ErrorCode = (typeof ERROR_CODES)[number];

export interface ApiErrorBody {
  code: ErrorCode;
  message: string;
}

/**
 * A typed error carrying the same `{ code, message }` shape the API's JSON
 * error responses use, plus the HTTP status they were sent with — so a
 * single type can represent an API error on both sides of the wire (thrown
 * server-side before serialization, or reconstructed client-side from a
 * failed response body).
 */
export class ApiError extends Error {
  readonly code: ErrorCode;
  readonly status: number;

  constructor(code: ErrorCode, message: string, status = 400) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.status = status;
  }

  /** The `{ error: { code, message } }` shape every API response uses. */
  toJSON(): { error: ApiErrorBody } {
    return { error: { code: this.code, message: this.message } };
  }

  /** Reconstructs an ApiError from a decoded `{ error: {...} }` response body. */
  static fromResponseBody(body: { error: ApiErrorBody }, status = 400): ApiError {
    return new ApiError(body.error.code, body.error.message, status);
  }

  static isApiError(value: unknown): value is ApiError {
    return value instanceof ApiError;
  }
}
