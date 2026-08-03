/**
 * @lacasa/api-client/resources/agents — ports apps/web/src/lib/agentsStore.js
 * plus the GET /agents/:id call userStore.js's fetchUserById made.
 */
import type { ApiClient } from '../core/client';

export interface AgentSummary {
  id: string;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  avatar: string | null;
  adsCount: number;
}

export interface AgentDetail {
  id: string;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  avatar: string | null;
  /** AD_CREATED events for this agent — the same measure AgentSummary uses. */
  adsCount: number;
  /** The agent's ads at stage SOLD. Detail only; the directory omits it. */
  dealsClosedCount: number;
}

export function createAgentsResource(client: ApiClient) {
  return {
    list() {
      return client.request<AgentSummary[]>({ method: 'GET', path: '/agents' });
    },

    getById(id: string) {
      return client.request<AgentDetail>({ method: 'GET', path: `/agents/${id}` });
    },
  };
}

export type AgentsResource = ReturnType<typeof createAgentsResource>;
