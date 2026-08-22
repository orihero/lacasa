// Proves three things for AdsEdit that used to be either hand-duplicated
// logic or a live bug:
//   1. the price preview is wired to @lacasa/domain's convertDisplayPrice
//      (same wiring AdsAdd.test.tsx covers for its own component);
//   2. the Instagram publish flow's caption is wired to @lacasa/domain's
//      buildCaption, driven end to end through the real accordion -> modal
//      -> Publish click path (not just calling the function directly);
//   3. editing an "additional info" option no longer throws — AdsEdit used
//      to reference an undefined `handleChangeOption`, a live ReferenceError
//      fixed alongside this migration.
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { convertDisplayPrice } from "@lacasa/domain";
import { HttpResponse, http } from "msw";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import "../../i18n";
import i18n from "../../i18n";
import regionData from "@lacasa/domain/data/regions";
import { useListStore } from "../../lib/adsListStore";
import { useUserStore } from "../../lib/userStore";
import { useUtilsStore } from "../../lib/utilsStore";
import { API_BASE, server } from "../../test-utils/msw";
import AdsEdit from "./AdsEdit";

const CURRENCY_RATE = 12700;
const REGION = regionData.regions[0];
const DISTRICT = regionData.districts.find((d) => d.region_id === REGION.id)!;

const AD = {
  id: "ad-1",
  agentId: "agent-1",
  title: "Nice flat",
  city: REGION.name,
  district: DISTRICT.name,
  address: "123 Main St",
  reference: "Near the park",
  type: "residential",
  category: "rent",
  repairment: "normal",
  rooms: 3,
  area: 50,
  storey: 2,
  floors: 5,
  furniture: "withFurniture",
  hashtags: "#new",
  price: 1000000,
  priceType: "uzs",
  stage: "1",
  description: "A nice flat",
  nearPlacesList: [] as string[],
  optionList: [{ id: 1, key: "Elevator", value: "yes" }],
  active: true,
  photos: ["https://cdn.example.com/ad1.jpg"],
  createdAt: { seconds: 0 },
  updatedAt: { seconds: 0 },
};

const IG_ACCOUNT = {
  igUserId: "ig-1",
  username: "lacasa_realty",
  expiresAt: null as string | null,
  profile_picture_url: "https://cdn.example.com/ig1.jpg",
  followers_count: 10,
  follows_count: 5,
  media_count: 20,
};

// Two entries: the modal's channel list only renders when
// currentUser.tgAccounts.length > 1 (a pre-existing quirk, not this
// migration's job to fix). Neither has title/username/avatar/member count
// — see services/tg.ts's file header for why that enrichment is gone.
const TG_ACCOUNTS = [{ id: 111 }, { id: 222 }];

function renderAdsEdit() {
  return render(
    <MemoryRouter initialEntries={[`/profile/${AD.id}/update/ads`]}>
      <Routes>
        <Route path="/profile/:id/update/ads" element={<AdsEdit />} />
      </Routes>
    </MemoryRouter>,
  );
}

describe("AdsEdit", () => {
  beforeEach(() => {
    useUserStore.setState({
      currentUser: { id: "agent-1", role: "agent", igAccounts: [IG_ACCOUNT], tgAccounts: [] },
      isLoading: false,
    });
    useUtilsStore.setState({ currency: [], nearbyPlaceData: [], isLoading: true });
    useListStore.setState({ list: [], myList: [], adsData: {}, stageCount: { stage1: 0, stage2: 0 }, isLoading: true });

    server.use(
      http.get(`${API_BASE}/ads/${AD.id}`, () => HttpResponse.json(AD)),
      http.get(`${API_BASE}/utils/currency`, () => HttpResponse.json({ code: "USD", rate: CURRENCY_RATE })),
      http.get(`${API_BASE}/utils/nearby-places`, () => HttpResponse.json([])),
    );
  });

  afterEach(() => {
    // See AdsAdd.test.tsx's afterEach for why currentUser isn't nulled out
    // here: AdsEdit's JSX reads `currentUser.igAccounts` unguarded too.
    useUtilsStore.setState({ currency: [], nearbyPlaceData: [], isLoading: true });
    useListStore.setState({ list: [], myList: [], adsData: {}, stageCount: { stage1: 0, stage2: 0 }, isLoading: true });
  });

  it("previews the USD equivalent of the loaded ad's price via domain's convertDisplayPrice", async () => {
    const { container } = renderAdsEdit();

    await waitFor(() => expect(useUtilsStore.getState().currency).toEqual([{ id: "USD", currency: CURRENCY_RATE }]));
    await screen.findByDisplayValue("Nice flat");

    const preview = container.querySelector(".field.price i");
    await waitFor(() =>
      expect(preview?.textContent).toBe(convertDisplayPrice(AD.price, "uzs", CURRENCY_RATE)),
    );
  });

  it("publishes to Instagram with a caption built by domain's buildCaption, driven through the real accordion -> modal -> Publish click path", async () => {
    let capturedBody: any = null;
    server.use(
      http.post(`${API_BASE}/publish/instagram`, async ({ request }) => {
        capturedBody = await request.json();
        return HttpResponse.json({ publication: { id: "pub-1" }, results: [{ igUserId: "ig-1", igUsername: "lacasa_realty", ok: true }] });
      }),
    );
    const user = userEvent.setup();
    renderAdsEdit();
    await screen.findByDisplayValue("Nice flat");

    // Expand the Instagram accordion (sets accordionExpanded to "ig", which
    // is what the modal's Publish button branches on).
    await user.click(screen.getByText("Instagram"));
    await user.click(screen.getByRole("button", { name: "Publish" }));

    const modalHeading = await screen.findByText(i18n.t("select_channels"));
    const modalContainer = modalHeading.closest(".tg-channel-list") as HTMLElement;
    await user.click(within(modalContainer).getByRole("checkbox"));
    await user.click(within(modalContainer).getByRole("button", { name: "Publish" }));

    await waitFor(() => expect(capturedBody).not.toBeNull());
    expect(capturedBody.adId).toBe(AD.id);
    expect(capturedBody.igUserIds).toEqual(["ig-1"]);
    expect(capturedBody.imageUrls).toEqual(["https://cdn.example.com/ad1.jpg"]);
    // Spot-checks that the caption is really domain's buildCaption(values,
    // priceType, t) output — "label: value unit \n" per field — rather than
    // some other string, without depending on react-hook-form's exact
    // getValues() snapshot shape (which includes every key reset() was
    // seeded with, registered input or not).
    expect(capturedBody.caption).toContain("Title: Nice flat");
    expect(capturedBody.caption).toContain("Price: 1000000 uzs");
    expect(capturedBody.caption).toContain("Hashtags: #new");
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
          publication: { id: "pub-1", adId: AD.id, channel: "TELEGRAM", status: "PUBLISHED" },
          results: (capturedBody.chatIds as string[]).map((chatId) => ({ chatId, ok: true, messageId: 1 })),
        });
      }),
    );
    useUserStore.setState({
      currentUser: { id: "agent-1", role: "agent", igAccounts: [IG_ACCOUNT], tgAccounts: TG_ACCOUNTS },
      isLoading: false,
    });

    const user = userEvent.setup();
    renderAdsEdit();
    await screen.findByDisplayValue("Nice flat");

    // Expand the Telegram accordion (sets accordionExpanded to "tg", which
    // is what the modal's Publish button branches on).
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
    expect(capturedBody.adId).toBe(AD.id);
    expect([...capturedBody.chatIds].sort()).toEqual(["111", "222"]);
  });

  it("editing an additional-info option updates it instead of throwing (handleChangeOption used to be undefined)", async () => {
    const user = userEvent.setup();
    renderAdsEdit();
    await screen.findByDisplayValue("Nice flat");

    const valueInput = await screen.findByDisplayValue("yes");
    await user.clear(valueInput);
    await user.type(valueInput, "no");

    expect(await screen.findByDisplayValue("no")).toBeInTheDocument();
  });
});
