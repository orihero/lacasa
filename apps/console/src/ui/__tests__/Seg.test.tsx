import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { Seg } from "../Seg";
import { render } from "./testUtils";

const options = [
  { value: "all", label: "All 8" },
  { value: "active", label: "Active 5" },
] as const;

describe("Seg", () => {
  it("marks only the active option as pressed, styled dark", () => {
    render(<Seg options={options} value="active" onChange={() => {}} />);
    const active = screen.getByRole("button", { name: "Active 5" });
    const inactive = screen.getByRole("button", { name: "All 8" });

    expect(active).toHaveAttribute("aria-pressed", "true");
    expect(active.className).toContain("bg-dark");
    expect(inactive).toHaveAttribute("aria-pressed", "false");
    expect(inactive.className).not.toContain("bg-dark");
  });

  it("calls onChange with the clicked option's value, not the current one", async () => {
    const onChange = vi.fn();
    render(<Seg options={options} value="all" onChange={onChange} />);
    await userEvent.click(screen.getByRole("button", { name: "Active 5" }));
    expect(onChange).toHaveBeenCalledExactlyOnceWith("active");
  });

  it("renders every option as a real, independently focusable button", () => {
    render(<Seg options={options} value="all" onChange={() => {}} />);
    expect(screen.getAllByRole("button")).toHaveLength(2);
  });
});
