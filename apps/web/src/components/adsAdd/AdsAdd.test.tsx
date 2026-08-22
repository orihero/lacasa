// Proves AdsAdd's price preview is actually wired to @lacasa/domain's
// convertDisplayPrice (currency[0]?.currency from useUtilsStore, the
// price input's live value, and the priceType toggle) rather than a
// hand-inlined copy of the same formula.
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { convertDisplayPrice } from "@lacasa/domain";
import { HttpResponse, http } from "msw";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import "../../i18n";
import i18n from "../../i18n";
import { useUserStore } from "../../lib/userStore";
import { useUtilsStore } from "../../lib/utilsStore";
import { API_BASE, server } from "../../test-utils/msw";
import AdsAdd from "./AdsAdd";

const CURRENCY_RATE = 12700;

function renderAdsAdd() {
  return render(
    <MemoryRouter initialEntries={["/profile/agent-1/create/ads"]}>
      <Routes>
        <Route path="/profile/:id/create/ads" element={<AdsAdd />} />
      </Routes>
    </MemoryRouter>,
  );
}

describe("AdsAdd — price preview wiring (domain's convertDisplayPrice)", () => {
  beforeEach(() => {
    useUserStore.setState({ currentUser: { id: "agent-1", role: "agent", igAccounts: [], tgAccounts: [] }, isLoading: false });
    useUtilsStore.setState({ currency: [], nearbyPlaceData: [], isLoading: true });

    server.use(
      http.get(`${API_BASE}/utils/currency`, () => HttpResponse.json({ code: "USD", rate: CURRENCY_RATE })),
      http.get(`${API_BASE}/utils/nearby-places`, () => HttpResponse.json([])),
    );
  });

  afterEach(() => {
    // Not resetting currentUser to null here: AdsAdd's JSX reads
    // `currentUser.igAccounts` without a guard on `currentUser` itself, so
    // nulling it out while the component is still mounted (RTL's cleanup()
    // — registered globally in the shared setup — runs after this
    // describe-scoped afterEach) would trigger a real render crash outside
    // the test itself. Each test's beforeEach already seeds a fresh
    // currentUser before rendering, so leaving the old one in place here is
    // harmless.
    useUtilsStore.setState({ currency: [], nearbyPlaceData: [], isLoading: true });
  });

  it("previews the USD equivalent (floor(price / rate) + \" $\") while priceType is so'm", async () => {
    const user = userEvent.setup();
    const { container } = renderAdsAdd();

    await waitFor(() => expect(useUtilsStore.getState().currency).toEqual([{ id: "USD", currency: CURRENCY_RATE }]));

    await user.type(screen.getByLabelText("Price"), "1000000");

    const preview = container.querySelector(".field.price i");
    await waitFor(() =>
      expect(preview?.textContent).toBe(convertDisplayPrice(1000000, "uzs", CURRENCY_RATE)),
    );
    expect(preview?.textContent).toBe("78 $");
  });

  it("previews the so'm equivalent (rate * price + \" so'm\") once priceType is switched to y.e (usd)", async () => {
    const user = userEvent.setup();
    const { container } = renderAdsAdd();

    await waitFor(() => expect(useUtilsStore.getState().currency).toEqual([{ id: "USD", currency: CURRENCY_RATE }]));

    await user.selectOptions(container.querySelector('select[name="priceType"]')!, "usd");
    await user.type(screen.getByLabelText("Price"), "100");

    const preview = container.querySelector(".field.price i");
    await waitFor(() =>
      expect(preview?.textContent).toBe(convertDisplayPrice(100, "usd", CURRENCY_RATE)),
    );
    expect(preview?.textContent).toBe(`${CURRENCY_RATE * 100} so'm`);
  });
});

// Two entries: the modal's channel list only renders when
// currentUser.tgAccounts.length > 1 (a pre-existing quirk, not this
// migration's job to fix). Neither has title/username/avatar/member count
// — see services/tg.ts's file header for why that enrichment is gone.
const TG_ACCOUNTS = [{ id: 111 }, { id: 222 }];

describe("AdsAdd — Telegram publish (server-side, no bot token in the browser)", () => {
  beforeEach(() => {
    useUserStore.setState({
      currentUser: { id: "agent-1", role: "agent", igAccounts: [], tgAccounts: TG_ACCOUNTS },
      isLoading: false,
    });
    useUtilsStore.setState({ currency: [], nearbyPlaceData: [], isLoading: true });

    server.use(
      http.get(`${API_BASE}/utils/currency`, () => HttpResponse.json({ code: "USD", rate: CURRENCY_RATE })),
      http.get(`${API_BASE}/utils/nearby-places`, () => HttpResponse.json([])),
    );
  });

  afterEach(() => {
    // See the price-preview describe block's afterEach for why currentUser
    // isn't nulled out here.
    useUtilsStore.setState({ currency: [], nearbyPlaceData: [], isLoading: true });
  });

  it("publishes to Telegram through the server's POST /publish/telegram route, driven through the real accordion -> modal -> Publish click path, and never touches api.telegram.org", async () => {
    let capturedBody: any = null;
    let hitTelegramDirectly = false;
    server.use(
      http.all("https://api.telegram.org/*", () => {
        hitTelegramDirectly = true;
        return HttpResponse.json({ ok: false });
      }),
      http.post(`${API_BASE}/publish/telegram`, async ({ request }) => {
        capturedBody = await request.json();
        return HttpResponse.json({
          publication: { id: "pub-1", adId: capturedBody.adId, channel: "TELEGRAM", status: "PUBLISHED" },
          results: (capturedBody.chatIds as string[]).map((chatId) => ({ chatId, ok: true, messageId: 1 })),
        });
      }),
    );

    const user = userEvent.setup();
    renderAdsAdd();

    // Expand the Telegram accordion (sets accordionExpanded to "tg") and
    // open the channel-picker modal via its own Publish button (sets
    // openModal to "tg", which is what the modal's Publish button branches
    // on for AdsAdd — see the onClick handler in the Modal below).
    await user.click(screen.getByText("Telegram"));
    await user.click(screen.getByRole("button", { name: "Publish" }));

    const modalHeading = await screen.findByText(i18n.t("select_channels"));
    const modalContainer = modalHeading.closest(".tg-channel-list") as HTMLElement;
    for (const checkbox of within(modalContainer).getAllByRole("checkbox")) {
      await user.click(checkbox);
    }
    await user.click(within(modalContainer).getByRole("button", { name: "Publish" }));

    await waitFor(() => expect(capturedBody).not.toBeNull());
    expect(hitTelegramDirectly).toBe(false);
    expect(capturedBody.adId).toMatch(/^draft-/);
    expect([...capturedBody.chatIds].sort()).toEqual(["111", "222"]);
    // hashtagsValue + "\n" + caption — AdsAdd's onSubmitTG-specific prefix
    // (AdsEdit's does not do this; see its own onSubmitTG's comment).
    expect(capturedBody.caption.startsWith("\n")).toBe(true);
  });
});
