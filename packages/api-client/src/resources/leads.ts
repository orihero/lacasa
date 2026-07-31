/**
 * @lacasa/api-client/resources/leads — ports apps/web/src/lib/useLeadStore.js.
 *
 * The old store's fetchLeadListByCwrk was a byte-for-byte duplicate of
 * fetchLeadList (the server has always scoped both to the caller's own
 * agent context — see docs/05 Phase D notes); this resource exposes a
 * single `list()`.
 */
import type { LeadInput } from '@lacasa/domain';
import type { ApiClient } from '../core/client';

export interface Lead {
  id: string;
  fullName: string;
  phone: string;
  email: string | null;
  budget: number | null;
  comment: string | null;
  conversationComment: string | null;
  status: string;
  source: string | null;
  callbackDate: string | null;
  active: boolean;
  agentId: string;
  coworkerId: string;
  createdAt: { seconds: number };
  updatedAt: { seconds: number };
}

export function createLeadsResource(client: ApiClient) {
  return {
    list() {
      return client.request<Lead[]>({ method: 'GET', path: '/leads' });
    },

    getById(id: string) {
      return client.request<Lead>({ method: 'GET', path: `/leads/${id}` });
    },

    create(input: LeadInput) {
      return client.request<Lead>({ method: 'POST', path: '/leads', body: input });
    },

    update(id: string, input: LeadInput) {
      return client.request<Lead>({ method: 'PATCH', path: `/leads/${id}`, body: input });
    },

    remove(id: string) {
      return client.request<void>({ method: 'DELETE', path: `/leads/${id}` });
    },
  };
}

export type LeadsResource = ReturnType<typeof createLeadsResource>;
