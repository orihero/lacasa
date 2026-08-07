import { describe, expect, it } from "vitest";
import {
  EMPTY_FORM_STATE,
  adReferenceOf,
  adTitleOf,
  buildAdInput,
  buildFormStateFromAd,
  isFormValid,
  stageKeyOf,
  updatedAtOf,
  validateForm,
  type AdFormState,
} from "../adFormFields";
import { makeAd } from "./fixtures";

describe("buildFormStateFromAd", () => {
  it("narrows every real field off an Ad's unknown-typed index signature", () => {
    const ad = makeAd();
    const form = buildFormStateFromAd(ad);
    expect(form).toMatchObject({
      title: "Bright 3-room apartment in Chilonzor",
      city: "Toshkent shahri",
      district: "Chilonzor tumani",
      type: "residential",
      category: "sale",
      price: "78000",
      priceType: "usd",
      rooms: "3",
      area: "65",
      storey: "4",
      floors: "9",
      repairment: "good",
      furniture: "withoutFurniture",
      description: "A bright corner apartment.",
      hashtags: "#chilonzor #3xona",
      active: true,
      markAsSold: false,
    });
  });

  it("falls back to blank/false rather than throwing on missing or malformed fields", () => {
    const ad = makeAd({
      title: undefined,
      rooms: null,
      repairment: null,
      furniture: undefined,
      active: undefined,
      type: "not-a-real-type",
    });
    const form = buildFormStateFromAd(ad);
    expect(form.title).toBe("");
    expect(form.rooms).toBe("");
    expect(form.repairment).toBe("");
    expect(form.furniture).toBe("");
    expect(form.active).toBe(true); // fallback default, not a fabricated false
    expect(form.type).toBe(""); // an unrecognized wire value is never trusted
  });

  it("reads markAsSold off stage '2', never a fabricated flag", () => {
    expect(buildFormStateFromAd(makeAd({ stage: "2" })).markAsSold).toBe(true);
    expect(buildFormStateFromAd(makeAd({ stage: "1" })).markAsSold).toBe(false);
    expect(buildFormStateFromAd(makeAd({ stage: "3" })).markAsSold).toBe(false);
  });
});

describe("buildAdInput", () => {
  const filled: AdFormState = {
    ...EMPTY_FORM_STATE,
    title: "  Bright flat  ",
    city: "Tashkent",
    district: "Chilonzor",
    type: "residential",
    category: "sale",
    price: "78000",
    priceType: "usd",
    rooms: "3",
    area: "65",
    storey: "",
    floors: "",
    repairment: "good",
    furniture: "",
    description: "  ",
    hashtags: "",
    photos: ["https://cdn.example/a.jpg"],
    active: true,
    markAsSold: false,
  };

  it("trims strings, coerces numeric fields, and clears nullable fields to null (never '')", () => {
    const input = buildAdInput(filled);
    expect(input.title).toBe("Bright flat");
    expect(input.rooms).toBe(3);
    expect(input.area).toBe(65);
    expect(input.storey).toBeNull();
    expect(input.floors).toBeNull();
    expect(input.furniture).toBeNull();
    expect(input.description).toBeNull(); // whitespace-only collapses to null
    expect(input.photos).toEqual(["https://cdn.example/a.jpg"]);
  });

  it("sets stage from markAsSold on a regular save: '2' when on, '1' otherwise", () => {
    expect(buildAdInput({ ...filled, markAsSold: false }).stage).toBe("1");
    expect(buildAdInput({ ...filled, markAsSold: true }).stage).toBe("2");
  });

  it("forceDraft always wins, regardless of markAsSold", () => {
    expect(buildAdInput({ ...filled, markAsSold: true }, { forceDraft: true }).stage).toBe("3");
    expect(buildAdInput({ ...filled, markAsSold: false }, { forceDraft: true }).stage).toBe("3");
  });

  it("omits type/category when unset rather than sending an empty string the server would reject", () => {
    const input = buildAdInput({ ...filled, type: "", category: "" });
    expect(input.type).toBeUndefined();
    expect(input.category).toBeUndefined();
  });
});

describe("validateForm / isFormValid", () => {
  it("requires title/city/district/price/type/category by default (Save)", () => {
    const errors = validateForm(EMPTY_FORM_STATE);
    expect(errors.title).toBeTruthy();
    expect(errors.city).toBeTruthy();
    expect(errors.district).toBeTruthy();
    expect(errors.price).toBeTruthy();
    expect(errors.type).toBeTruthy();
    expect(errors.category).toBeTruthy();
    expect(isFormValid(EMPTY_FORM_STATE)).toBe(false);
  });

  it("still flags a missing type/category even once title/city/district/price are filled — Save must never silently no-op", () => {
    // Regression: type/category are NOT NULL columns (schema.prisma) and
    // used to be checked only by a second, error-less gate in
    // ListingEditorScreen's handleSubmit — Save would just do nothing, with
    // no field hint and no mutation, if only these two were left blank.
    const almostValid: AdFormState = {
      ...EMPTY_FORM_STATE,
      title: "A title",
      city: "Tashkent",
      district: "Chilonzor",
      price: "1000",
    };
    const errors = validateForm(almostValid);
    expect(errors.type).toBeTruthy();
    expect(errors.category).toBeTruthy();
    expect(isFormValid(almostValid)).toBe(false);
  });

  it("drops the required-ness checks for a draft, but still catches real format violations", () => {
    const errors = validateForm(EMPTY_FORM_STATE, { requireCore: false });
    expect(errors.title).toBeUndefined();
    expect(errors.city).toBeUndefined();
    expect(errors.price).toBeUndefined();
    expect(errors.type).toBeUndefined();
    expect(errors.category).toBeUndefined();
    expect(isFormValid(EMPTY_FORM_STATE, { requireCore: false })).toBe(true);

    const tooLongTitle = { ...EMPTY_FORM_STATE, title: "x".repeat(301) };
    expect(validateForm(tooLongTitle, { requireCore: false }).title).toBeTruthy();
  });

  it("rejects a negative or non-numeric price even when present", () => {
    expect(validateForm({ ...EMPTY_FORM_STATE, price: "-5" }).price).toBeTruthy();
    expect(validateForm({ ...EMPTY_FORM_STATE, price: "not-a-number" }).price).toBeTruthy();
    expect(validateForm({ ...EMPTY_FORM_STATE, price: "0" }).price).toBeUndefined();
  });

  it("a fully filled form with valid values passes", () => {
    const valid: AdFormState = {
      ...EMPTY_FORM_STATE,
      title: "A title",
      city: "Tashkent",
      district: "Chilonzor",
      type: "residential",
      category: "sale",
      price: "1000",
    };
    expect(isFormValid(valid)).toBe(true);
  });
});

describe("display helpers", () => {
  it("adTitleOf falls back honestly instead of rendering a blank title", () => {
    expect(adTitleOf(makeAd({ title: "Real title" }))).toBe("Real title");
    expect(adTitleOf(makeAd({ title: undefined }))).toBe("Untitled listing");
  });

  it("adReferenceOf is null (not fabricated) when the ad has none", () => {
    expect(adReferenceOf(makeAd({ reference: "a3f21" }))).toBe("a3f21");
    expect(adReferenceOf(makeAd({ reference: undefined }))).toBeNull();
  });

  it("stageKeyOf only trusts one of the three real AdStage keys", () => {
    expect(stageKeyOf(makeAd({ stage: "2" }))).toBe("2");
    expect(stageKeyOf(makeAd({ stage: "not-a-stage" }))).toBeUndefined();
  });

  it("updatedAtOf narrows the {seconds} wire shape without throwing", () => {
    expect(updatedAtOf(makeAd({ updatedAt: { seconds: 1_722_600_000 } }))).toEqual({ seconds: 1_722_600_000 });
    expect(updatedAtOf(makeAd({ updatedAt: undefined }))).toBeNull();
    expect(updatedAtOf(makeAd({ updatedAt: "not-a-date-shape" }))).toBe("not-a-date-shape");
  });
});
