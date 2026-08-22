/**
 * src/data/useLeads — the agent's lead pipeline (List, Kanban, and the lead
 * detail flows all read off the same `useLeads()` list; there's no
 * per-status endpoint to fetch a narrower slice from).
 */
import { useMutation, useQuery, useQueryClient, type UseMutationResult, type UseQueryResult } from '@tanstack/react-query';
import type { Lead } from '@lacasa/api-client';
import type { ApiError } from '@lacasa/domain';
import type { LeadInput } from '@lacasa/domain';
import { apiClient } from '@/lib/apiClient';
import { queryKeys } from './queryKeys';

export function useLeads(): UseQueryResult<Lead[]> {
  return useQuery({
    queryKey: queryKeys.leads.list(),
    queryFn: () => apiClient.leads.list(),
  });
}

export interface UpdateLeadVariables {
  id: string;
  input: LeadInput;
}

/**
 * Covers both a field edit (LeadUpdate-style forms) and a Kanban drag
 * (`{ input: { status } }`) — the API has one PATCH for both, so this stays
 * one hook rather than a `useMoveLead` + `useEditLead` pair that would just
 * call the same endpoint two different ways.
 */
export function useUpdateLead(): UseMutationResult<Lead, ApiError, UpdateLeadVariables> {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: UpdateLeadVariables) => apiClient.leads.update(id, input),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.leads.all });
    },
  });
}
