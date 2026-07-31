// Every entity this app tracks (ads, leads) follows the same shape when
// something happens to it: write/update the row, then record an
// ActivityEvent pointing at it (agent/coworker + `${model}Id`). Factored out
// here so adService and leadService can't drift out of sync on how that
// pairing is recorded — see docs/03-data-model.md's statistics mapping,
// which is built entirely from these events.

// `actor` is `{ agentId, coworkerId }` (see middleware/roles.js#actorFields
// / effectiveAgentId) plus an optional `meta` object for events that carry
// extra context (publish.js's start/complete/abort events use this).
export async function logActivityEvent(ctx, type, actor, extra = {}) {
  return ctx.prisma.activityEvent.create({
    data: {
      type,
      agentId: actor.agentId,
      coworkerId: actor.coworkerId ?? null,
      ...(actor.meta ? { meta: actor.meta } : {}),
      ...extra,
    },
  });
}

// Creates a row on `ctx.prisma[model]` (model is a Prisma client accessor,
// e.g. "ad" | "lead") and logs the matching ActivityEvent in one call. Takes
// the full Prisma `.create()` args object (`{ data, include? }`) as `args`,
// exactly like calling `ctx.prisma[model].create(args)` directly would.
export async function createWithActivityEvent(ctx, model, eventType, args, actor) {
  const row = await ctx.prisma[model].create(args);
  await logActivityEvent(ctx, eventType, actor, { [`${model}Id`]: row.id });
  return row;
}
