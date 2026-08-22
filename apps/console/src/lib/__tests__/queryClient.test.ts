import { describe, expect, it, vi } from 'vitest';
import { ApiError } from '@lacasa/domain';
import { onSessionExpired } from '../sessionExpired';
import { notifyIfSessionExpired } from '../queryClient';

describe('notifyIfSessionExpired', () => {
  it('emits sessionExpired for a real 401 ApiError', () => {
    const listener = vi.fn();
    const unsubscribe = onSessionExpired(listener);

    notifyIfSessionExpired(new ApiError('unauthorized', 'Token expired', 401));

    unsubscribe();
    expect(listener).toHaveBeenCalledOnce();
  });

  it('does not emit for a 403 — "not allowed to do this" is not "the whole session is bad"', () => {
    const listener = vi.fn();
    const unsubscribe = onSessionExpired(listener);

    notifyIfSessionExpired(new ApiError('forbidden', 'Not your ad', 403));

    unsubscribe();
    expect(listener).not.toHaveBeenCalled();
  });

  it('does not emit for a non-ApiError failure (a network blip, a thrown string)', () => {
    const listener = vi.fn();
    const unsubscribe = onSessionExpired(listener);

    notifyIfSessionExpired(new Error('Failed to fetch'));
    notifyIfSessionExpired('boom');

    unsubscribe();
    expect(listener).not.toHaveBeenCalled();
  });
});
