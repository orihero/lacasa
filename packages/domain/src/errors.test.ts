import { describe, expect, it } from 'vitest';
import { ApiError, ERROR_CODES } from './errors';

describe('ApiError', () => {
  it('carries code, message, and status', () => {
    const err = new ApiError('not_found', 'Ad not found', 404);
    expect(err.code).toBe('not_found');
    expect(err.message).toBe('Ad not found');
    expect(err.status).toBe(404);
    expect(err).toBeInstanceOf(Error);
  });

  it('defaults status to 400', () => {
    expect(new ApiError('validation', 'bad input').status).toBe(400);
  });

  it('serializes to the { error: { code, message } } wire shape', () => {
    const err = new ApiError('forbidden', 'Not allowed for this role');
    expect(err.toJSON()).toEqual({
      error: { code: 'forbidden', message: 'Not allowed for this role' },
    });
    expect(JSON.stringify(err)).toBe(JSON.stringify(err.toJSON()));
  });

  it('round-trips through fromResponseBody', () => {
    const original = new ApiError('email_taken', 'Email is already registered', 409);
    const rebuilt = ApiError.fromResponseBody(original.toJSON(), 409);
    expect(rebuilt.code).toBe(original.code);
    expect(rebuilt.message).toBe(original.message);
    expect(rebuilt.status).toBe(409);
  });

  it('isApiError narrows correctly', () => {
    expect(ApiError.isApiError(new ApiError('internal', 'oops'))).toBe(true);
    expect(ApiError.isApiError(new Error('plain'))).toBe(false);
    expect(ApiError.isApiError(null)).toBe(false);
  });

  it('ERROR_CODES contains every code the API currently returns', () => {
    expect(ERROR_CODES).toEqual(
      expect.arrayContaining([
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
      ]),
    );
  });
});
