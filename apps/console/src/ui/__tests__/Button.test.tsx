import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { Button } from "../Button";
import type { IconComponent } from "../icons";
import { render } from "./testUtils";

// A plain local stand-in for a real Phosphor icon, not an import from
// "../icons" — @phosphor-icons/react is hoisted to the workspace root (see
// testUtils.tsx's file header for the underlying hoisting conflict), so its
// exported components are permanently tagged as built against the *other*
// React copy; React 19's reconciler refuses to mount them at all ("A React
// Element from an older version of React was rendered") regardless of which
// root does the mounting. Button's own logic — that it renders whatever
// `icon`/`iconRight` component it's given — doesn't need a real Phosphor
// glyph to verify.
const FakeIcon: IconComponent = (props) => <svg data-testid="fake-icon" {...props} />;

describe("Button", () => {
  it("defaults to the neutral pill variant", () => {
    render(<Button>Export</Button>);
    const el = screen.getByRole("button", { name: "Export" });
    expect(el.className).toContain("bg-pill");
    expect(el.className).not.toContain("bg-accent");
  });

  it("renders the primary variant as the accent-discipline CTA (lime bg, olive text)", () => {
    render(<Button variant="primary">Add new post</Button>);
    const el = screen.getByRole("button", { name: "Add new post" });
    expect(el.className).toContain("bg-accent");
    expect(el.className).toContain("text-accent-text");
  });

  it("renders the dark variant", () => {
    render(<Button variant="dark">Export as CSV</Button>);
    expect(screen.getByRole("button", { name: "Export as CSV" }).className).toContain("bg-dark");
  });

  it("renders the danger variant as red text on the neutral pill, not a red fill", () => {
    render(<Button variant="danger">Delete</Button>);
    const el = screen.getByRole("button", { name: "Delete" });
    expect(el.className).toContain("text-err");
    expect(el.className).toContain("bg-pill");
  });

  it("is a real, clickable <button type=button> by default (never a bare submit)", async () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Save</Button>);
    const el = screen.getByRole("button", { name: "Save" });
    expect(el).toHaveAttribute("type", "button");
    await userEvent.click(el);
    expect(onClick).toHaveBeenCalledOnce();
  });

  it("renders a leading and/or trailing icon when given", () => {
    const { container } = render(
      <Button icon={FakeIcon} iconRight={FakeIcon}>
        Create lead
      </Button>,
    );
    expect(container.querySelectorAll('[data-testid="fake-icon"]')).toHaveLength(2);
  });
});
