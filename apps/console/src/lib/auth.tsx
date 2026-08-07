/**
 * src/lib/auth — session state for the whole app: who's logged in, and the
 * gate every authenticated route sits behind.
 *
 * The token itself lives in localStorageTokenStorage (localStorage), not in
 * this context — AuthProvider only ever asks it "is there a token?" via
 * `localStorageTokenStorage.getToken()` rather than reading localStorage
 * directly a second time, so there is exactly one place that knows how the
 * token is persisted (lib/apiClient.ts), which apps/mobile can later swap
 * for expo-secure-store without touching this file at all. Note this is
 * NOT reached through `apiClient.tokenStorage` — createLaCasaApiClient()
 * (@lacasa/api-client) returns only the resource groups (ads, auth, …), not
 * the underlying ApiClient's `.tokenStorage`/`.baseUrl`, so the same
 * TokenStorage instance has to be imported on its own.
 */
import { createContext, useContext, useEffect, useMemo, useState, type ReactElement, type ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { ApiError } from '@lacasa/domain';
import type { AuthUser } from '@lacasa/api-client';
import { apiClient, localStorageTokenStorage } from './apiClient';
import { onSessionExpired } from './sessionExpired';
import { LoadingState } from '@/ui/States';

export type AuthStatus = 'loading' | 'authenticated' | 'anonymous';

export interface AuthContextValue {
  user: AuthUser | null;
  status: AuthStatus;
  login(email: string, password: string): Promise<void>;
  logout(): void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }): ReactElement {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [status, setStatus] = useState<AuthStatus>('loading');

  // Runs once on mount: a token surviving a refresh doesn't mean it's still
  // good (the user could've been deleted, or the token could've expired) —
  // it has to be checked against GET /auth/me before the app trusts it.
  useEffect(() => {
    let cancelled = false;

    async function checkSession() {
      const token = await localStorageTokenStorage.getToken();
      if (!token) {
        if (!cancelled) setStatus('anonymous');
        return;
      }

      try {
        const { user: me } = await apiClient.auth.me();
        if (!cancelled) {
          setUser(me);
          setStatus('authenticated');
        }
      } catch (error) {
        // Only a 401 means the token itself is bad — anything else (a
        // network blip, a 500) shouldn't throw away a token that might
        // still be good on the next request, so it's left in storage and
        // only the in-memory session drops to anonymous.
        if (ApiError.isApiError(error) && error.status === 401) {
          await localStorageTokenStorage.setToken(null);
        }
        if (!cancelled) setStatus('anonymous');
      }
    }

    void checkSession();
    return () => {
      cancelled = true;
    };
  }, []);

  // A 401 discovered later in the session (queryClient.ts's global
  // QueryCache/MutationCache onError, not just this component's own
  // mount-time checkSession above) reaches here through sessionExpired.ts —
  // same recovery as the 401 branch above, just reachable from any request.
  useEffect(() => {
    return onSessionExpired(() => {
      void localStorageTokenStorage.setToken(null);
      setUser(null);
      setStatus('anonymous');
    });
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      status,
      async login(email: string, password: string) {
        const { token, user: loggedInUser } = await apiClient.auth.login({ email, password });
        await localStorageTokenStorage.setToken(token);
        setUser(loggedInUser);
        setStatus('authenticated');
      },
      logout() {
        // Fire-and-forget: the in-memory session drops immediately (the UI
        // shouldn't wait on a localStorage write to redirect), the token
        // clear just needs to land before the next request goes out, which
        // the Authorization header on that request already guarantees by
        // re-reading tokenStorage each time (see core/client.ts).
        void localStorageTokenStorage.setToken(null);
        setUser(null);
        setStatus('anonymous');
      },
    }),
    [user, status],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// The FOUNDATION CONTRACT fixes AuthProvider/useAuth/RequireAuth to this one
// file; splitting useAuth out to satisfy fast-refresh would just move the
// contract violation instead of avoiding it.
// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
}

/**
 * Route guard: never flashes the login screen while the token is still
 * being checked (`status === 'loading'` renders a full-page loading state
 * instead of deciding early), and remembers where the agent was headed so a
 * post-login redirect can send them back instead of dumping them on
 * /statistics.
 */
export function RequireAuth({ children }: { children: ReactNode }): ReactElement {
  const { status } = useAuth();
  const location = useLocation();

  if (status === 'loading') {
    return <LoadingState label="Checking your session…" />;
  }

  if (status === 'anonymous') {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return <>{children}</>;
}
