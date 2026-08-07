/**
 * @lacasa/api-client/core/client — wires an injected Transport + TokenStorage
 * into the one method every resource module (../resources/*.ts) calls.
 */
import type { HttpMethod, QueryParams, Transport, TokenStorage } from './transport';

export interface ApiRequest {
  method: HttpMethod;
  path: string;
  query?: QueryParams;
  body?: unknown;
  headers?: Record<string, string>;
}

export interface CreateApiClientOptions {
  transport: Transport;
  tokenStorage: TokenStorage;
  /** Prepended verbatim to every request's `path` (e.g. "http://localhost:4200/api"). */
  baseUrl: string;
}

export interface ApiClient {
  request<T>(req: ApiRequest): Promise<T>;
  readonly tokenStorage: TokenStorage;
  readonly baseUrl: string;
}

/**
 * AWAITS tokenStorage.getToken() before building the Authorization header
 * and handing the request to the transport — so a TokenStorage backed by
 * something slow (expo-secure-store's cold read on mobile launch, e.g.)
 * can never race a request out the door without its token attached. See
 * core/client.test.ts's delayed-resolve TokenStorage test, which asserts
 * the transport is not invoked until getToken() resolves.
 */
export function createApiClient(options: CreateApiClientOptions): ApiClient {
  const { transport, tokenStorage, baseUrl } = options;

  async function request<T>(req: ApiRequest): Promise<T> {
    const token = await tokenStorage.getToken();
    const headers: Record<string, string> = { ...req.headers };
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }
    return transport.request<T>({
      method: req.method,
      url: `${baseUrl}${req.path}`,
      query: req.query,
      body: req.body,
      headers,
    });
  }

  return { request, tokenStorage, baseUrl };
}
