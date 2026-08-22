/**
 * @lacasa/api-client/resources/coworkers — ports
 * apps/web/src/lib/useCoworkerStore.js plus the create/update/delete calls
 * previously inlined in CoworkerAdd.jsx / CoworkerUpdate.jsx.
 */
import type { CoworkerCreateInput, CoworkerUpdateInput } from '@lacasa/domain';
import type { ApiClient } from '../core/client';

export interface Coworker {
  id: string;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  avatar: string | null;
  agentId: string;
}

export function createCoworkersResource(client: ApiClient) {
  return {
    list() {
      return client.request<Coworker[]>({ method: 'GET', path: '/coworkers' });
    },

    getById(id: string) {
      return client.request<Coworker>({ method: 'GET', path: `/coworkers/${id}` });
    },

    create(input: CoworkerCreateInput) {
      return client.request<Coworker>({ method: 'POST', path: '/coworkers', body: input });
    },

    update(id: string, input: CoworkerUpdateInput) {
      return client.request<Coworker>({ method: 'PATCH', path: `/coworkers/${id}`, body: input });
    },

    remove(id: string) {
      return client.request<void>({ method: 'DELETE', path: `/coworkers/${id}` });
    },
  };
}

export type CoworkersResource = ReturnType<typeof createCoworkersResource>;
