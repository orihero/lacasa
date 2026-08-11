// Every entity this app tracks (ads, leads) follows the same shape when
// something happens to it: write/update the row, then record an
// ActivityEvent pointing at it (agent/coworker + `${model}Id`). Factored out
// here so adService and leadService can't drift out of sync on how that
// pairing is recorded — see docs/03-data-model.md's statistics mapping,
// which is built entirely from these events.
//
// This is also the one place a real-time push notification gets triggered
// from (pushService.js#notifyForActivityEvent, imported below). Every
// ActivityEvent write funnels through this function, so hooking push in
// here — instead of adding a call at every adService/leadService (and
// future) call site — is what guarantees a model that starts logging
// through createWithActivityEvent later gets push "for free" and can't
// forget to wire it. That is a deliberate, narrow exception to this app's
// usual lib-never-imports-services direction: activity.js is kept as this
// single choke point specifically so a cross-cutting concern like push has
// exactly one place to attach, rather than services importing each other's
// side effects. pushService.js itself imports nothing from lib/activity.js,
// so this stays a one-way dependency, not a cycle.
import * as pushService from "../services/pushService.js";

// `actor` is `{ agentId, coworkerId }` (see middleware/roles.js#actorFields
// / effectiveAgentId) plus an optional `meta` object for events that carry
// extra context (publish.js's start/complete/abort events use this).
export async function logActivityEvent(ctx, type, actor, extra = {}) {
  const event = await ctx.prisma.activityEvent.create({
    data: {
      type,
      agentId: actor.agentId,
      coworkerId: actor.coworkerId ?? null,
      ...(actor.meta ? { meta: actor.meta } : {}),
      ...extra,
    },
  });

  // Fire-and-forget: notifyForActivityEvent never throws or rejects (see
  // its own header comment and pushService.js's file-header guarantee), so
  // this is awaited only to keep behaviour deterministic in tests, not
  // because a slow or failed push is allowed to delay or fail this write's
  // own caller. It runs after the ActivityEvent row has already committed,
  // so even a mid-send crash leaves the event correctly recorded.
  await pushService.notifyForActivityEvent(ctx, event);

  return event;
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
