/**
 * Builds the value -> key reverse of a literal string-keyed map.
 *
 * Every *_REV export in this directory is derived from its forward map via
 * this helper instead of being hand-maintained as a second literal object —
 * a hand-written reverse map can silently drift out of sync with the
 * forward map (a renamed value, a removed key) with nothing to catch it.
 */
export function invert<K extends string, V extends PropertyKey>(
  map: Record<K, V>,
): Record<V, K> {
  const result = {} as Record<V, K>;
  for (const key of Object.keys(map) as K[]) {
    result[map[key]] = key;
  }
  return result;
}
