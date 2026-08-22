// ContactUs.jsx used to POST directly to https://api.telegram.org with a
// hardcoded bot token literal committed in this file (docs/05-migration-plan.md
// Phase E — the worst of the browser-side Telegram leaks). This proves the
// form now goes through the server's public POST /api/contact instead, and
// that a failed send is surfaced to the user rather than silently swallowed.
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { HttpResponse, http } from "msw";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import "../../../i18n";
import i18n from "../../../i18n";
import { API_BASE, server } from "../../../test-utils/msw";
import ContactUs from "./ContactUs";

describe("ContactUs", () => {
  let alertSpy;

  beforeEach(() => {
    alertSpy = vi.spyOn(window, "alert").mockImplementation(() => {});
  });

  afterEach(() => {
    alertSpy.mockRestore();
  });

  it("posts to the server's POST /api/contact route, never directly to api.telegram.org", async () => {
    let capturedBody = null;
    let hitTelegramDirectly = false;
    server.use(
      http.all("https://api.telegram.org/*", () => {
        hitTelegramDirectly = true;
        return HttpResponse.json({ ok: false });
      }),
      http.post(`${API_BASE}/contact`, async ({ request }) => {
        capturedBody = await request.json();
        return HttpResponse.json({ ok: true }, { status: 202 });
      }),
    );
    const user = userEvent.setup();
    render(<ContactUs />);

    await user.type(screen.getByPlaceholderText(i18n.t("fullName")), "Dilnoza Yusupova");
    await user.type(screen.getByPlaceholderText(i18n.t("phone")), "+998901234501");
    await user.type(screen.getByPlaceholderText(i18n.t("message")), "Hello there");
    await user.click(screen.getByText(i18n.t("sendMassage")));

    await waitFor(() => expect(capturedBody).not.toBeNull());
    expect(hitTelegramDirectly).toBe(false);
    expect(capturedBody).toEqual({
      name: "Dilnoza Yusupova",
      phone: "+998901234501",
      message: "Hello there",
    });
    await waitFor(() => expect(alertSpy).toHaveBeenCalledWith(i18n.t("messageSent")));
  });

  it("rejects an invalid phone number client-side without ever making a request", async () => {
    let called = false;
    server.use(
      http.post(`${API_BASE}/contact`, () => {
        called = true;
        return HttpResponse.json({ ok: true }, { status: 202 });
      }),
    );
    const user = userEvent.setup();
    render(<ContactUs />);

    await user.type(screen.getByPlaceholderText(i18n.t("fullName")), "Dilnoza Yusupova");
    await user.type(screen.getByPlaceholderText(i18n.t("phone")), "12345");
    await user.click(screen.getByText(i18n.t("sendMassage")));

    expect(alertSpy).toHaveBeenCalledWith(i18n.t("invalidPhone"));
    expect(called).toBe(false);
  });

  it("surfaces a failed send instead of silently swallowing it", async () => {
    server.use(
      http.post(`${API_BASE}/contact`, () =>
        HttpResponse.json({ error: { code: "contact_relay_failed", message: "boom" } }, { status: 502 }),
      ),
    );
    const user = userEvent.setup();
    render(<ContactUs />);

    await user.type(screen.getByPlaceholderText(i18n.t("fullName")), "Dilnoza Yusupova");
    await user.type(screen.getByPlaceholderText(i18n.t("phone")), "+998901234501");
    await user.click(screen.getByText(i18n.t("sendMassage")));

    await waitFor(() => expect(alertSpy).toHaveBeenCalledWith(i18n.t("messageSendFailed")));
  });

  it("surfaces rate limiting (429) with a specific message", async () => {
    server.use(
      http.post(`${API_BASE}/contact`, () => HttpResponse.json({ error: { code: "rate_limited" } }, { status: 429 })),
    );
    const user = userEvent.setup();
    render(<ContactUs />);

    await user.type(screen.getByPlaceholderText(i18n.t("fullName")), "Dilnoza Yusupova");
    await user.type(screen.getByPlaceholderText(i18n.t("phone")), "+998901234501");
    await user.click(screen.getByText(i18n.t("sendMassage")));

    await waitFor(() => expect(alertSpy).toHaveBeenCalledWith(i18n.t("messageRateLimited")));
  });
});
