import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { HttpResponse, http } from "msw";
import { MemoryRouter } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import "../../i18n";
import { useUserStore } from "../../lib/userStore";
import { API_BASE, server } from "../../test-utils/msw";
import CoworkerAdd from "./CoworkerAdd";

// CoworkerAdd's <label>s aren't associated with their <input>s (no
// htmlFor/id), so fields are queried by react-hook-form's `name` attribute
// instead of getByLabelText.
describe("CoworkerAdd — phone validation (domain's phoneValidationRule)", () => {
  beforeEach(() => {
    useUserStore.setState({ currentUser: { id: "agent-1", role: "agent" }, isLoading: false });
  });

  afterEach(() => {
    useUserStore.setState({ currentUser: null, isLoading: true });
  });

  it("shows the Uzbekistan phone format error and never calls the API when the phone doesn't match +998XXXXXXXXX", async () => {
    let coworkerCalls = 0;
    server.use(
      http.post(`${API_BASE}/coworkers`, () => {
        coworkerCalls += 1;
        return HttpResponse.json({ id: "cw-1" });
      }),
    );
    const user = userEvent.setup();

    const { container } = render(
      <MemoryRouter>
        <CoworkerAdd />
      </MemoryRouter>,
    );

    await user.type(container.querySelector('input[name="fullName"]'), "Ann Smith");
    await user.type(container.querySelector('input[name="phone"]'), "0901234567");
    await user.type(container.querySelector('input[name="email"]'), "ann@example.com");
    await user.type(container.querySelector('input[name="password"]'), "secret1");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(await screen.findByText("Invalid Uzbekistan phone number")).toBeInTheDocument();
    expect(coworkerCalls).toBe(0);
  });

  it("accepts a valid +998XXXXXXXXX phone and submits it as phoneNumber to POST /coworkers", async () => {
    let capturedBody = null;
    server.use(
      http.post(`${API_BASE}/coworkers`, async ({ request }) => {
        capturedBody = await request.json();
        return HttpResponse.json({ id: "cw-1" });
      }),
    );
    const user = userEvent.setup();

    const { container } = render(
      <MemoryRouter>
        <CoworkerAdd />
      </MemoryRouter>,
    );

    await user.type(container.querySelector('input[name="fullName"]'), "Ann Smith");
    await user.type(container.querySelector('input[name="phone"]'), "+998901234567");
    await user.type(container.querySelector('input[name="email"]'), "ann@example.com");
    await user.type(container.querySelector('input[name="password"]'), "secret1");
    await user.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => expect(capturedBody).not.toBeNull());
    expect(capturedBody.phoneNumber).toBe("+998901234567");
    expect(screen.queryByText("Invalid Uzbekistan phone number")).not.toBeInTheDocument();
  });
});
