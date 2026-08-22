import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createAgentsResource } from './agents';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage(null), baseUrl: 'http://api.test' });
  return { agents: createAgentsResource(client), calls };
}

describe('agents resource', () => {
  it('list() requests GET /agents', async () => {
    const { agents, calls } = setup([]);

    await agents.list();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/agents' });
  });

  it('getById requests GET /agents/:id', async () => {
    const { agents, calls } = setup({ id: 'agent-1' });

    await agents.getById('agent-1');

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/agents/agent-1' });
  });
});
