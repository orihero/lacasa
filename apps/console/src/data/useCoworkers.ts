/**
 * src/data/useCoworkers — the agent's team roster, plus a derivation helper
 * for the two metrics the prototype's Coworkers table wants that the
 * Coworker payload itself does not carry (PLAN.md §3.7's "11 listings, 3
 * closed, 2 days ago" row):
 *
 *  - "listings"     -> count of `Ad.coworkerId === coworker.id` from the
 *                      agent's own `useMyAds()` list. Real, just not on the
 *                      Coworker object — this derives it instead of adding
 *                      a fake field.
 *  - "last active"   -> latest CoworkerStatisticEvent.createdAt for that
 *                      coworker, from `useCoworkerStatistics()`.
 *
 * "Closed" (leads with status SUCCESS) is deliberately NOT derived here:
 * `LeadStatus` has no `SUCCESS` member in Prisma yet (PLAN.md §4, Decision
 * 6.4) — there is no real value to compute. The Coworkers screen must Flag
 * that gap rather than call a helper that would have to invent one.
 */
import { useMutation, useQuery, useQueryClient, type UseMutationResult, type UseQueryResult } from '@tanstack/react-query';
import type { Ad, Coworker, CoworkerStatisticEvent } from '@lacasa/api-client';
import type { ApiError, CoworkerUpdateInput } from '@lacasa/domain';
import { toValidDate, type CoworkerCreateInput } from '@lacasa/domain';
import { apiClient } from '@/lib/apiClient';
import { queryKeys } from './queryKeys';

export function useCoworkers(): UseQueryResult<Coworker[]> {
  return useQuery({
    queryKey: queryKeys.coworkers.list(),
    queryFn: () => apiClient.coworkers.list(),
  });
}

export function useCreateCoworker(): UseMutationResult<Coworker, ApiError, CoworkerCreateInput> {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (input: CoworkerCreateInput) => apiClient.coworkers.create(input),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.coworkers.all });
    },
  });
}

export function useDeleteCoworker(): UseMutationResult<void, ApiError, string> {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => apiClient.coworkers.remove(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.coworkers.all });
    },
  });
}

export interface UpdateCoworkerVariables {
  id: string;
  input: CoworkerUpdateInput;
}

/**
 * PATCH /coworkers/:id — originally a Coworkers-screen-local hook (this
 * module's exports were fixed to list/create/delete before the screen's own
 * "edit" row action needed one); promoted here alongside its siblings.
 * `@lacasa/api-client`'s coworkers resource already exposes a real
 * `.update()` backing a real endpoint, so this wires the same real mutation
 * `useCreateCoworker`/`useDeleteCoworker` do, not a placeholder.
 */
export function useUpdateCoworker(): UseMutationResult<Coworker, ApiError, UpdateCoworkerVariables> {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, input }: UpdateCoworkerVariables) => apiClient.coworkers.update(id, input),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.coworkers.all });
    },
  });
}

export interface CoworkerMetrics {
  listingsCount: number;
  lastActiveAt: Date | null;
}

/**
 * Pure so it's trivially testable and so the screen can call it once per
 * coworker over lists it already fetched — it does not fetch anything
 * itself.
 */
export function deriveCoworkerMetrics(
  coworkerId: string,
  ads: readonly Ad[],
  events: readonly CoworkerStatisticEvent[],
): CoworkerMetrics {
  const listingsCount = ads.filter((ad) => ad.coworkerId === coworkerId).length;

  let lastActiveAt: Date | null = null;
  for (const event of events) {
    if (event.coworkerId !== coworkerId) continue;
    const eventDate = toValidDate(event.createdAt);
    if (eventDate && (!lastActiveAt || eventDate > lastActiveAt)) {
      lastActiveAt = eventDate;
    }
  }

  return { listingsCount, lastActiveAt };
}
