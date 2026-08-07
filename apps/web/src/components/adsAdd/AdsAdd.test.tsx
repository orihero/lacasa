// Proves AdsAdd's price preview is actually wired to @lacasa/domain's
// convertDisplayPrice (currency[0]?.currency from useUtilsStore, the
// price input's live value, and the priceType toggle) rather than a
// hand-inlined copy of the same formula.
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { convertDisplayPrice } from "@lacasa/domain";
import { HttpResponse, http } from "msw";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import "../../i18n";
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
