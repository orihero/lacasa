// Footer.jsx duplicated ContactUs.jsx's exact bug: a hardcoded Telegram bot
// token literal and chat id, POSTing straight to api.telegram.org from the
// browser. Same fix, same test shape as ContactUs.test.jsx.
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { HttpResponse, http } from "msw";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import "../../i18n";
import i18n from "../../i18n";
import { API_BASE, server } from "../../test-utils/msw";
import Footer from "./Footer";

describe("Footer's contact form", () => {
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
    render(<Footer />);

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
  });

  it("surfaces a failed send instead of silently swallowing it", async () => {
    server.use(
      http.post(`${API_BASE}/contact`, () =>
        HttpResponse.json({ error: { code: "contact_relay_failed", message: "boom" } }, { status: 502 }),
      ),
    );
    const user = userEvent.setup();
    render(<Footer />);

    await user.type(screen.getByPlaceholderText(i18n.t("fullName")), "Dilnoza Yusupova");
    await user.type(screen.getByPlaceholderText(i18n.t("phone")), "+998901234501");
    await user.click(screen.getByText(i18n.t("sendMassage")));

    await waitFor(() => expect(alertSpy).toHaveBeenCalledWith(i18n.t("messageSendFailed")));
  });
});
