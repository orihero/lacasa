/**
 * src/lib/sessionExpired — a tiny synchronous pub/sub so a 401 discovered by
 * react-query (queryClient.ts's global QueryCache/MutationCache `onError`,
 * fired from *any* query or mutation, at any point in the session) can reach
 * AuthProvider (lib/auth.tsx), which is the only place allowed to flip
 * `status` to 'anonymous'.
 *
 * A plain event emitter, not a shared piece of React state, on purpose:
 * queryClient.ts is a module-level singleton constructed outside any React
 * tree (wired into QueryClientProvider in App.tsx) and cannot call a hook, so
 * there is no `useAuth()` it could reach for directly. This keeps the two
 * files decoupled — queryClient.ts doesn't import React or auth.tsx, and
 * auth.tsx doesn't import react-query — while still letting a 401 anywhere in
 * the app trigger the same recovery path AuthProvider's mount-time session
 * check already has, not just the first request of the session.
 */
type Listener = () => void;

const listeners = new Set<Listener>();

export function onSessionExpired(listener: Listener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function emitSessionExpired(): void {
  for (const listener of listeners) listener();
}
