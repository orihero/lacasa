import { describe, expect, it } from 'vitest';
import { API_CLIENT_PACKAGE_NAME, createLaCasaApiClient, describeDependency } from './index';
import { createFakeTokenStorage, createFakeTransport } from './testing/fakeTransport';

describe('@lacasa/api-client root entry point', () => {
  it('resolves and can import @lacasa/domain', () => {
    expect(API_CLIENT_PACKAGE_NAME).toBe('@lacasa/api-client');
    expect(describeDependency()).toBe('@lacasa/api-client depends on @lacasa/domain');
  });

  it('createLaCasaApiClient wires every resource onto one shared ApiClient', async () => {
    const { transport, calls } = createFakeTransport([]);
    const api = createLaCasaApiClient({
      transport,
      tokenStorage: createFakeTokenStorage('token'),
      baseUrl: 'http://localhost:4200/api',
    });

    expect(Object.keys(api).sort()).toEqual(
      ['ads', 'agents', 'auth', 'coworkers', 'leads', 'publish', 'statistics', 'uploads', 'users', 'utils'].sort(),
    );

    await api.leads.list();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://localhost:4200/api/leads' });
    expect(calls[0]!.headers?.Authorization).toBe('Bearer token');
  });
});
