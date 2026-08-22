import { describe, expect, it, vi } from 'vitest';
import { emitSessionExpired, onSessionExpired } from '../sessionExpired';

describe('sessionExpired', () => {
  it('calls every subscribed listener on emit', () => {
    const a = vi.fn();
    const b = vi.fn();
    onSessionExpired(a);
    onSessionExpired(b);

    emitSessionExpired();

    expect(a).toHaveBeenCalledOnce();
    expect(b).toHaveBeenCalledOnce();
  });

  it('stops calling a listener once it unsubscribes', () => {
    const listener = vi.fn();
    const unsubscribe = onSessionExpired(listener);

    unsubscribe();
    emitSessionExpired();

    expect(listener).not.toHaveBeenCalled();
  });

  it('emitting with no listeners subscribed is a no-op, not a throw', () => {
    expect(() => emitSessionExpired()).not.toThrow();
  });
});
