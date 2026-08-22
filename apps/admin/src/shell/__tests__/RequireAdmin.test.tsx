/**
 * RequireAdmin's three outcomes. They live in lib/auth.tsx, but they are a
 * ROUTING contract — routes.tsx wraps the shell in this guard — which is why
 * the suite sits with the shell.
 *
 * All three branches are load-bearing and none of them is interchangeable with
 * another:
 *
 *   loading    — never flash the login screen while the token is still being
 *                checked; a refresh with a valid token must not blink through
 *                /login.
 *   anonymous  — redirect, remembering where they were headed.
 *   non-admin  — ForbiddenScreen, rendered INSTEAD OF the shell. Not a
 *                redirect to /login: they are already signed in, so login
 *                would authenticate them again, the guard would refuse again,
 *                and the two would trade the browser back and forth forever.
 *
 * The session is driven through the real AuthProvider with the API client
 * mocked, rather than through a stubbed context, because the mount-time
 * GET /auth/me — and specifically the fact that THE ROLE IS RE-READ FROM THE
 * SERVER on every load rather than trusted from the login response — is half
 * of what is being tested.
 */
import type { AuthUser } from "@lacasa/api-client";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import i18n from "@/i18n";
import { apiClient, localStorageTokenStorage } from "@/lib/apiClient";
import { AuthProvider, RequireAdmin } from "@/lib/auth";

// vi.mock is hoisted above the imports, so the bindings above are already the
// stubs by the time anything runs; they are imported statically only so their
// real types survive for vi.mocked().
vi.mock("@/lib/apiClient", () => ({
  // EnvStrip (rendered by ForbiddenScreen) reads this.
  API_BASE_URL: "http://localhost:4200/api",
  apiClient: { auth: { me: vi.fn(), login: vi.fn() } },
  localStorageTokenStorage: { getToken: vi.fn(), setToken: vi.fn() },
}));

function user(role: string): AuthUser {
  return {
    id: "u-1",
    fullName: "Dilnoza Yusupova",
    email: "dilnoza@example.com",
    phoneNumber: null,
    role,
  };
}

function renderGuard() {
  return render(
    <MemoryRouter initialEntries={["/audit"]}>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<p>the login screen</p>} />
          <Route
            path="/audit"
            element={
              <RequireAdmin>
                <p>the audit log</p>
              </RequireAdmin>
            }
          />
        </Routes>
      </AuthProvider>
    </MemoryRouter>,
  );
}

beforeAll(async () => {
  await i18n.changeLanguage("en");
});

beforeEach(() => {
  vi.clearAllMocks();
  vi.mocked(localStorageTokenStorage.setToken).mockResolvedValue(undefined);
});

describe("RequireAdmin", () => {
  it("holds on a loading state while the token is still being checked", async () => {
    // A token that is still being read: the guard must not paint /login in the
    // meantime, or a refresh with a valid session blinks through the login
    // screen on every page load.
    vi.mocked(localStorageTokenStorage.getToken).mockReturnValue(
      new Promise<string | null>(() => {}),
    );

    renderGuard();

    expect(await screen.findByRole("status")).toHaveTextContent("Checking your session…");
    expect(screen.queryByText("the login screen")).toBeNull();
    expect(screen.queryByText("the audit log")).toBeNull();
  });

  it("redirects an anonymous visitor to the login screen", async () => {
    vi.mocked(localStorageTokenStorage.getToken).mockResolvedValue(null);

    renderGuard();

    expect(await screen.findByText("the login screen")).toBeTruthy();
    // No token, so no request is made at all — there is nothing to revalidate.
    expect(apiClient.auth.me).not.toHaveBeenCalled();
  });

  it("refuses a signed-in non-admin with the forbidden screen, not a redirect", async () => {
    vi.mocked(localStorageTokenStorage.getToken).mockResolvedValue("token");
    vi.mocked(apiClient.auth.me).mockResolvedValue({ user: user("agent") });

    renderGuard();

    expect(await screen.findByText("This is the control room")).toBeTruthy();
    // It states WHICH account, verbatim as the server sent the role: "you are
    // not an admin" is unhelpful when the real situation is "you are signed in
    // as the wrong one of your two accounts".
    expect(screen.getByText("dilnoza@example.com")).toBeTruthy();
    expect(screen.getByText("agent")).toBeTruthy();
    expect(screen.queryByText("the login screen")).toBeNull();
    expect(screen.queryByText("the audit log")).toBeNull();
  });

  it("lets an admin through, matching the role case-insensitively", async () => {
    // The serializer emits "admin", but nothing stops a future one — or a
    // hand-issued token in a fixture — from sending "ADMIN". Being strict
    // about case would lock a real admin out with no explanation; being
    // lenient cannot let anyone else in, because no other role string
    // lowercases to "admin".
    vi.mocked(localStorageTokenStorage.getToken).mockResolvedValue("token");
    vi.mocked(apiClient.auth.me).mockResolvedValue({ user: user("ADMIN") });

    renderGuard();

    expect(await screen.findByText("the audit log")).toBeTruthy();
  });
});
