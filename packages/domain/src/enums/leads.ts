import { invert } from './invert';

// Bidirectional map between the wire/frontend lead status values and the
// Postgres enum values in apps/api/prisma/schema.prisma. Also doubles as
// the ordered set of Kanban columns in LeadKanbanList — see
// ../leads/transitions.ts.
export const LEAD_STATUS = {
  new: 'NEW',
  could_not_connect: 'COULD_NOT_CONNECT',
  need_to_call_back: 'NEED_TO_CALL_BACK',
  rejected: 'REJECTED',
  accepted: 'ACCEPTED',
} as const;

export type LeadStatusKey = keyof typeof LEAD_STATUS;

export const LEAD_STATUS_REV = invert(LEAD_STATUS);
