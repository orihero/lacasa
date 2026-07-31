import { describe, expect, it } from 'vitest';
import {
  DOMAIN_PACKAGE_NAME,
  ping,
  AD_TYPE,
  LEAD_STATUS,
  ALL_CHANNELS,
  buildCaption,
  convertDisplayPrice,
  isValidUzPhone,
  phoneValidationRule,
  resolveCardMoveAction,
  formatCreatedAt,
  toValidDate,
  adInputSchema,
  leadInputSchema,
  registerSchema,
  igPublishSchema,
  ApiError,
  ERROR_CODES,
} from './index';

describe('@lacasa/domain root entry point', () => {
  it('resolves and exports the package identity', () => {
    expect(DOMAIN_PACKAGE_NAME).toBe('@lacasa/domain');
    expect(ping()).toBe('pong');
  });

  it('re-exports the enums', () => {
    expect(AD_TYPE.residential).toBe('RESIDENTIAL');
    expect(LEAD_STATUS.new).toBe('NEW');
    expect(ALL_CHANNELS).toContain('OLX');
  });

  it('re-exports the ads helpers', () => {
    expect(buildCaption({ title: 'x' }, 'uzs', (k) => k)).toContain('title');
    expect(convertDisplayPrice(100, 'usd', 1)).toBe('100 so\'m');
  });

  it('re-exports the phone validator', () => {
    expect(isValidUzPhone('+998901234567')).toBe(true);
    expect(phoneValidationRule('req', 'inv').required).toBe('req');
  });

  it('re-exports the lead transition resolver', () => {
    expect(resolveCardMoveAction('new', 'new', { id: '1' })).toEqual({ type: 'move' });
  });

  it('re-exports the date formatters', () => {
    expect(formatCreatedAt(null)).toBe('');
    expect(toValidDate(null)).toBeNull();
  });

  it('re-exports the zod schemas', () => {
    expect(adInputSchema.parse({}).title).toBeUndefined();
    expect(leadInputSchema.parse({}).status).toBeUndefined();
    expect(registerSchema.safeParse({}).success).toBe(false);
    expect(igPublishSchema.safeParse({}).success).toBe(false);
  });

  it('re-exports ApiError and ERROR_CODES', () => {
    expect(new ApiError('not_found', 'x').code).toBe('not_found');
    expect(ERROR_CODES).toContain('validation');
  });
});
