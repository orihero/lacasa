// Proves the account-type step actually shapes the POST /auth/register body
// the way @lacasa/domain's realtorApplicationSchema expects (mockups/
// SCREENS.md §13): a buyer sends no realtor block, a solo agent sends the
// choice alone, and an agency sends its name and team size — with the same
// schema rejecting a bad office phone before the request is ever made.
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { HttpResponse, http } from "msw";
import { MemoryRouter } from "react-router-dom";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { useUserStore } from "../../lib/userStore";
import { useListStore } from "../../lib/adsListStore";
import { API_BASE, server } from "../../test-utils/msw";
import Register from "./register";

function renderRegister() {
  return render(
    <MemoryRouter initialEntries={["/register"]}>
      <Register />
    </MemoryRouter>,
  );
}

// Captures whatever the form posts, so each test can assert on the body
// rather than on the component's internal state.
function captureRegisterBody() {
  const seen = { body: null, calls: 0 };
  server.use(
    http.post(`${API_BASE}/auth/register`, async ({ request }) => {
      seen.body = await request.json();
      seen.calls += 1;
      return HttpResponse.json({ token: "test-token", user: { id: "u1", role: "user" } }, { status: 201 });
    }),
  );
  return seen;
}

async function fillCommonFields(user) {
  await user.type(screen.getByPlaceholderText("Full name"), "Dilnoza Yusupova");
  await user.type(screen.getByPlaceholderText("Phone number"), "+998901234501");
  await user.type(screen.getByPlaceholderText("Email"), "dilnoza@example.com");
  await user.type(screen.getByPlaceholderText("Password"), "secret123");
}

describe("Register — account type", () => {
  beforeEach(() => {
    // The success path calls both of these; neither is what's under test.
    vi.spyOn(useUserStore.getState(), "fetchUserInfo").mockResolvedValue(undefined);
    vi.spyOn(useListStore.getState(), "fetchAdsList").mockResolvedValue(undefined);
  });

  it("posts no realtor block for the default buyer choice", async () => {
    const user = userEvent.setup();
    const seen = captureRegisterBody();
    renderRegister();

    await fillCommonFields(user);
    await user.click(screen.getByRole("button", { name: /^Register$/ }));

    await waitFor(() => expect(seen.calls).toBe(1));
    expect(seen.body.realtor).toBeUndefined();
    expect(seen.body).toMatchObject({ fullName: "Dilnoza Yusupova", email: "dilnoza@example.com" });
  });

  it("asks an agency for nothing extra until Agency is picked", async () => {
    const user = userEvent.setup();
    renderRegister();

    expect(screen.queryByText("Realtor type")).not.toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: /Realtor/ }));
    expect(screen.getByText("Realtor type")).toBeInTheDocument();
    expect(screen.queryByPlaceholderText("Agency name")).not.toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Agency" }));
    expect(screen.getByPlaceholderText("Agency name")).toBeInTheDocument();
    expect(screen.getByText("Team size")).toBeInTheDocument();
  });

  it("posts the choice alone for a solo agent", async () => {
    const user = userEvent.setup();
    const seen = captureRegisterBody();
    renderRegister();

    await user.click(screen.getByRole("button", { name: /Realtor/ }));
    await fillCommonFields(user);
    await user.click(screen.getByRole("button", { name: "Create realtor account" }));

    await waitFor(() => expect(seen.calls).toBe(1));
    expect(seen.body.realtor).toEqual({ kind: "solo" });
  });

  it("posts the agency's name, office phone and team size", async () => {
    const user = userEvent.setup();
    const seen = captureRegisterBody();
    renderRegister();

    await user.click(screen.getByRole("button", { name: /Realtor/ }));
    await user.click(screen.getByRole("button", { name: "Agency" }));
    await fillCommonFields(user);
    await user.type(screen.getByPlaceholderText("Agency name"), "La Casa Realty");
    await user.type(screen.getByPlaceholderText("Office phone (optional)"), "+998712001020");
    await user.click(screen.getByRole("button", { name: "6–15" }));
    await user.click(screen.getByRole("button", { name: "Create realtor account" }));

    await waitFor(() => expect(seen.calls).toBe(1));
    expect(seen.body.realtor).toEqual({
      kind: "agency",
      agencyName: "La Casa Realty",
      officePhone: "+998712001020",
      teamSize: "six_to_fifteen",
    });
  });

  it("omits an empty office phone rather than failing the +998 rule", async () => {
    const user = userEvent.setup();
    const seen = captureRegisterBody();
    renderRegister();

    await user.click(screen.getByRole("button", { name: /Realtor/ }));
    await user.click(screen.getByRole("button", { name: "Agency" }));
    await fillCommonFields(user);
    await user.type(screen.getByPlaceholderText("Agency name"), "La Casa Realty");
    await user.click(screen.getByRole("button", { name: "Create realtor account" }));

    await waitFor(() => expect(seen.calls).toBe(1));
    expect(seen.body.realtor).toEqual({
      kind: "agency",
      agencyName: "La Casa Realty",
      teamSize: "just_me",
    });
  });

  it("refuses to send a malformed office phone", async () => {
    const user = userEvent.setup();
    const seen = captureRegisterBody();
    renderRegister();

    await user.click(screen.getByRole("button", { name: /Realtor/ }));
    await user.click(screen.getByRole("button", { name: "Agency" }));
    await fillCommonFields(user);
    await user.type(screen.getByPlaceholderText("Agency name"), "La Casa Realty");
    await user.type(screen.getByPlaceholderText("Office phone (optional)"), "712001020");
    await user.click(screen.getByRole("button", { name: "Create realtor account" }));

    // Caught client-side by the same schema the API uses — no request at all.
    await waitFor(() => expect(screen.getByPlaceholderText("Agency name")).toBeInTheDocument());
    expect(seen.calls).toBe(0);
  });
});
