/**
 * @lacasa/api-client/testing — fakes shared by src/core/client.test.ts and
 * every src/resources/*.test.ts. Not exported from the package's public
 * entry point (src/index.ts): these are test doubles for this package's own
 * suite, not part of the shipped API.
 */
import type { Transport, TransportRequest, TokenStorage } from '../core/transport';

export interface FakeTransport {
  transport: Transport;
  calls: TransportRequest[];
}

/** Records every request it receives and resolves them all to `response`. */
export function createFakeTransport<T = unknown>(response?: T): FakeTransport {
  const calls: TransportRequest[] = [];
  const transport: Transport = {
    request<R>(req: TransportRequest): Promise<R> {
      calls.push(req);
      return Promise.resolve(response as unknown as R);
    },
  };
  return { transport, calls };
}

/** Resolves getToken() immediately with a fixed value. */
export function createFakeTokenStorage(token: string | null = null): TokenStorage {
  let current = token;
  return {
    getToken: () => Promise.resolve(current),
    setToken: (t) => {
      current = t;
      return Promise.resolve();
    },
  };
}

/**
 * Resolves getToken() only after `delayMs`, flipping `resolved.current` to
 * true at that moment — lets a test assert the client hasn't fired the
 * request yet while the "cold start" read is still in flight.
 */
export function createDelayedTokenStorage(
  token: string | null,
  delayMs = 20,
): { tokenStorage: TokenStorage; resolved: { current: boolean } } {
  const resolved = { current: false };
  const tokenStorage: TokenStorage = {
    getToken: () =>
      new Promise((resolve) => {
        setTimeout(() => {
          resolved.current = true;
          resolve(token);
        }, delayMs);
      }),
    setToken: () => Promise.resolve(),
  };
  return { tokenStorage, resolved };
}
