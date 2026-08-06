import { screen } from "@testing-library/dom";
import { describe, expect, it } from "vitest";
import { Avatar, initials } from "../Avatar";
import { render } from "./testUtils";

describe("initials", () => {
  it("takes the first letter of the first two words", () => {
    expect(initials("Dilnoza Yusupova")).toBe("DY");
    expect(initials("Javlon Rustamov")).toBe("JR");
  });

  it("falls back to the first two letters of a single-word name", () => {
    expect(initials("Cher")).toBe("CH");
  });

  it("is deterministic — same name, same chip, every call", () => {
    const calls = Array.from({ length: 5 }, () => initials("Aziz Karimov"));
    expect(new Set(calls).size).toBe(1);
    expect(calls[0]).toBe("AK");
  });

  it("degrades gracefully on empty input instead of throwing", () => {
    expect(initials("")).toBe("");
    expect(initials("   ")).toBe("");
  });
});

describe("Avatar", () => {
  it("renders a deterministic initials chip when there is no photo", () => {
    render(<Avatar name="Dilnoza Yusupova" />);
    expect(screen.getByText("DY")).toBeInTheDocument();
  });

  it("prefers a real photo over the initials chip when src is given", () => {
    render(<Avatar name="Dilnoza Yusupova" src="https://example.com/dy.jpg" />);
    expect(screen.queryByText("DY")).not.toBeInTheDocument();
    const img = screen.getByRole("img", { name: "Dilnoza Yusupova" });
    expect(img.tagName).toBe("IMG");
    expect(img).toHaveAttribute("src", "https://example.com/dy.jpg");
  });

  it("gives the initials chip the same accessible name as the person", () => {
    render(<Avatar name="Sardor Abdullayev" />);
    expect(screen.getByRole("img", { name: "Sardor Abdullayev" })).toHaveTextContent("SA");
  });

  it("colors the initials chip by tone", () => {
    render(<Avatar name="Aziz Karimov" tone="warn" />);
    expect(screen.getByText("AK").className).toContain("bg-warn-soft");
  });
});
