import { z } from 'zod';

/**
 * Builds a `z.enum(...)` over the *keys* of one of ./enums's wire-format
 * maps (e.g. AD_TYPE, LEAD_STATUS), instead of a hand-copied literal tuple
 * that could drift from the map it's meant to validate against.
 */
export function zodEnumFromKeys<T extends Record<string, PropertyKey>>(
  map: T,
): z.ZodEnum<[Extract<keyof T, string>, ...Extract<keyof T, string>[]]> {
  const keys = Object.keys(map) as [Extract<keyof T, string>, ...Extract<keyof T, string>[]];
  return z.enum(keys);
}
