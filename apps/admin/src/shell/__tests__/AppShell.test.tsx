/**
 * The frame's landmarks and the single source of the page title.
 *
 * These are not cosmetic assertions. The shell is the only thing on this
 * surface that says where an admin is and which database they are pointed at,
 * and every screen spec is written against "the topbar owns the page's one
 * <h1>" — a screen that grew its own heading, or a rail row that lit for the
 * wrong route, would go unnoticed by every other suite in the app.
 */
import { render, screen, within } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import i18n from "@/i18n";
import { apiClient, localStorageTokenStorage } from "@/lib/apiClient";
import { AuthProvider } from "@/lib/auth";
import { queryKeys } from "@/lib/queryKeys";
import { AppShell } from "../AppShell";

vi.mock("@/lib/apiClient", () => ({
  API_BASE_URL: "http://localhost:4200/api",
  apiClient: { auth: { me: vi.fn(), login: vi.fn() } },
  localStorageTokenStorage: { getToken: vi.fn(), setToken: vi.fn() },
}));

function renderShell(route: string, queryClient = new QueryClient()) {
  return render(
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <MemoryRouter initialEntries={[route]}>
          <Routes>
            <Route element={<AppShell />} path="/">
              <Route path="users" element={<p>the directory</p>} />
              <Route path="applications" element={<p>the queue</p>} />
              <Route path="*" element={<p>no screen</p>} />
            </Route>
          </Routes>
        </MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>,
  );
}

beforeAll(async () => {
  await i18n.changeLanguage("en");
});

beforeEach(() => {
  vi.clearAllMocks();
  vi.mocked(localStorageTokenStorage.getToken).mockResolvedValue("token");
  vi.mocked(localStorageTokenStorage.setToken).mockResolvedValue(undefined);
  vi.mocked(apiClient.auth.me).mockResolvedValue({
    user: {
      id: "u-1",
      fullName: "Dilnoza Yusupova",
      email: "dilnoza@example.com",
      phoneNumber: null,
      role: "admin",
    },
  });
});

describe("AppShell", () => {
  it("frames the routed screen in the landmarks every screen spec assumes", () => {
    renderShell("/users");

    // The nav is an <aside> holding a labelled <nav>; the routed outlet is
    // inside <main>; the title bar is a <header>.
    const nav = screen.getByRole("navigation", { name: "Control room" });
    expect(nav.closest("aside")).not.toBeNull();
    expect(within(screen.getByRole("main")).getByText("the directory")).toBeTruthy();
    expect(screen.getByRole("banner")).toBeTruthy();
  });

  it("renders exactly one h1, and it is the topbar's page title", () => {
    renderShell("/users");

    const headings = screen.getAllByRole("heading", { level: 1 });
    expect(headings).toHaveLength(1);
    const [heading] = headings;
    expect(heading).toHaveTextContent("Users");
    expect(heading?.closest("header")).not.toBeNull();
  });

  it("titles an unmatched path 'Control room', never the last screen's title", () => {
    renderShell("/users/9c6e41af");

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent("Control room");
    expect(screen.getByText("no screen")).toBeTruthy();
  });

  it("marks the current route with aria-current and nothing else", () => {
    renderShell("/applications");

    const nav = screen.getByRole("navigation", { name: "Control room" });
    const current = within(nav)
      .getAllByRole("link")
      .filter((link) => link.getAttribute("aria-current") === "page");
    expect(current).toHaveLength(1);
    const [lit] = current;
    expect(lit).toHaveTextContent("Applications");
  });

  it("shows no count badge until something has loaded the overview", () => {
    // An unknown count renders as NO badge, never as 0: "nothing is waiting on
    // you" is the exact wrong thing to tell an admin looking at the queue.
    renderShell("/applications");

    const nav = screen.getByRole("navigation", { name: "Control room" });
    expect(within(nav).getByRole("link", { name: "Applications" })).toBeTruthy();
  });

  it("reads its badge counts out of the overview cache rather than fetching", () => {
    const queryClient = new QueryClient();
    queryClient.setQueryData(queryKeys.overview.summary(), {
      users: { total: 1284 },
      applications: { pending: 3 },
    });

    renderShell("/applications", queryClient);

    const nav = screen.getByRole("navigation", { name: "Control room" });
    expect(within(nav).getByRole("link", { name: "Applications3" })).toBeTruthy();
    // Grouped through the shared formatter, so the rail and the overview agree
    // on what 1284 looks like.
    expect(within(nav).getByRole("link", { name: "Users1,284" })).toBeTruthy();
  });

  it("names the topbar's inert controls, and gives the bell no unread pip", async () => {
    renderShell("/users");

    const bell = await screen.findByRole("button", {
      name: "Notifications (not available yet)",
    });
    expect(bell).toBeDisabled();
    expect(
      screen.getByRole("button", { name: "Settings (not available yet)" }),
    ).toBeDisabled();
  });
});
