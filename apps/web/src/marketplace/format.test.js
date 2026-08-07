import { describe, expect, it } from "vitest";
import {
  categoryLabel,
  floorLabel,
  groupPrice,
  locationLabel,
  priceParts,
  typeLabel,
} from "./format";

describe("marketplace format", () => {
  it("groups price with thousands separators, no decimals", () => {
    expect(groupPrice(78000)).toBe("78,000");
    expect(groupPrice(350)).toBe("350");
    expect(groupPrice(1234567.6)).toBe("1,234,568");
    expect(groupPrice(-5000)).toBe("-5,000");
  });

  it("renders sale prices bare and rent prices with /month", () => {
    expect(priceParts({ price: 78000, priceType: "usd", category: "sale" })).toEqual({
      body: "$78,000",
      suffix: "",
    });
    expect(priceParts({ price: 350, priceType: "usd", category: "rent" })).toEqual({
      body: "$350",
      suffix: "/month",
    });
  });

  it("renders UZS prices with the code instead of $", () => {
    expect(priceParts({ price: 4500000, priceType: "uzs", category: "rent" }).body).toBe(
      "4,500,000 UZS",
    );
  });

  it("labels category and type from the wire enum keys", () => {
    expect(categoryLabel({ category: "rent" })).toBe("For rent");
    expect(categoryLabel({ category: "sale" })).toBe("For sale");
    expect(typeLabel({ type: "residential" })).toBe("Residential");
    expect(typeLabel({ type: "nonresidential" })).toBe("Commercial");
  });

  it("formats floor as storey/floors and tolerates missing halves", () => {
    expect(floorLabel({ storey: 4, floors: 9 })).toBe("4/9");
    expect(floorLabel({ storey: 4, floors: null })).toBe("4");
    expect(floorLabel({ storey: null, floors: 9 })).toBeNull();
  });

  it("joins district and city, skipping blanks", () => {
    expect(locationLabel({ district: "Chilonzor", city: "Tashkent" })).toBe(
      "Chilonzor, Tashkent",
    );
    expect(locationLabel({ district: "", city: "Tashkent" })).toBe("Tashkent");
  });
});
