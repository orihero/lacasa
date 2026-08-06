import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { Switch } from "../Switch";
import { render } from "./testUtils";

describe("Switch", () => {
  it("renders an interactive button that reports its checked state and toggles it", async () => {
    const onChange = vi.fn();
    render(<Switch checked={false} onChange={onChange} label="Active" />);
    const el = screen.getByRole("switch", { name: "Active" });
    expect(el.tagName).toBe("BUTTON");
    expect(el).toHaveAttribute("aria-checked", "false");

    await userEvent.click(el);
    expect(onChange).toHaveBeenCalledExactlyOnceWith(true);
  });

  it("renders an inert, non-button indicator when readOnly — no click handler fires", async () => {
    const onChange = vi.fn();
    render(<Switch checked={true} onChange={onChange} readOnly label="Instagram connected" />);
    const el = screen.getByRole("switch", { name: "Instagram connected" });

    expect(el.tagName).not.toBe("BUTTON");
    expect(el).toHaveAttribute("aria-disabled", "true");
    expect(el).toHaveAttribute("aria-checked", "true");

    await userEvent.click(el);
    expect(onChange).not.toHaveBeenCalled();
  });

  it("does not throw when a read-only switch is rendered without an onChange at all", () => {
    expect(() => render(<Switch checked={false} readOnly label="YouTube" />)).not.toThrow();
  });
});
