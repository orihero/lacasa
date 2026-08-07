import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { CellMain, GhostRow, Table, TBody, TD, TH, Thumb, TR } from "../Table";
import type { IconComponent } from "../icons";
import { render } from "./testUtils";

// A plain local stand-in, not a real Phosphor import — see Button.test.tsx's
// FakeIcon comment for why @phosphor-icons/react can't be mounted in this
// test environment at all (a pre-existing, workspace-wide dependency
// hoisting conflict, not anything about CellMain's own logic).
const FakeIcon: IconComponent = (props) => <svg data-testid="fake-icon" {...props} />;

describe("Table", () => {
  it("gives every td the zebra/selected group-variant classes and both end-cap radius utilities", () => {
    // Tailwind's `first:`/`last:` variants compile to real `:first-child`/
    // `:last-child` CSS selectors (verified separately against this repo's
    // own Tailwind config — see Table.tsx's file header) — the utility
    // className is present on *every* cell's `class` attribute regardless of
    // position; it's the browser's pseudo-class matching, not conditional
    // JS, that decides which cell it actually paints. So every td carries
    // both radius utilities; only one of them ever visually applies.
    const { container } = render(
      <Table>
        <TBody>
          <TR>
            <TD>A</TD>
            <TD>B</TD>
            <TD>C</TD>
          </TR>
        </TBody>
      </Table>,
    );
    const cells = [...container.querySelectorAll("td")];
    expect(cells).toHaveLength(3);
    for (const cell of cells) {
      expect(cell.className).toContain("group-even:bg-surface-inner");
      expect(cell.className).toContain("group-data-[selected]:bg-accent-tint");
      expect(cell.className).toContain("first:rounded-l-input");
      expect(cell.className).toContain("last:rounded-r-input");
    }
  });

  it("marks a selected row's own DOM node with data-selected, unselected rows without it", () => {
    const { container } = render(
      <Table>
        <TBody>
          <TR selected>
            <TD>Selected</TD>
          </TR>
          <TR>
            <TD>Not selected</TD>
          </TR>
        </TBody>
      </Table>,
    );
    const rows = [...container.querySelectorAll("tr")];
    expect(rows[0]).toHaveAttribute("data-selected", "");
    expect(rows[1]).not.toHaveAttribute("data-selected");
  });

  it("wires a clickable row to a real onClick and marks it cursor-pointer, leaves non-clickable rows inert", async () => {
    const onClick = vi.fn();
    const { container } = render(
      <Table>
        <TBody>
          <TR onClick={onClick}>
            <TD>Clickable</TD>
          </TR>
          <TR>
            <TD>Inert</TD>
          </TR>
        </TBody>
      </Table>,
    );
    const rows = [...container.querySelectorAll("tr")];
    expect(rows[0]?.className).toContain("cursor-pointer");
    expect(rows[1]?.className).not.toContain("cursor-pointer");

    await userEvent.click(rows[0] as Element);
    expect(onClick).toHaveBeenCalledOnce();
  });

  it("makes a clickable row keyboard-reachable: tabbable, role=button, Enter/Space activate it", async () => {
    const onClick = vi.fn();
    const { container } = render(
      <Table>
        <TBody>
          <TR onClick={onClick}>
            <TD>Clickable</TD>
          </TR>
          <TR>
            <TD>Inert</TD>
          </TR>
        </TBody>
      </Table>,
    );
    const rows = [...container.querySelectorAll("tr")];
    expect(rows[0]).toHaveAttribute("tabindex", "0");
    expect(rows[0]).toHaveAttribute("role", "button");
    expect(rows[1]).not.toHaveAttribute("tabindex");
    expect(rows[1]).not.toHaveAttribute("role");

    (rows[0] as HTMLElement).focus();
    await userEvent.keyboard("{Enter}");
    expect(onClick).toHaveBeenCalledTimes(1);
    await userEvent.keyboard(" ");
    expect(onClick).toHaveBeenCalledTimes(2);
  });

  it("right-aligns a TH only when asked", () => {
    render(
      <table>
        <thead>
          <tr>
            <TH>Listing</TH>
            <TH align="right">Price</TH>
          </tr>
        </thead>
      </table>,
    );
    expect(screen.getByText("Listing").className).not.toContain("text-right");
    expect(screen.getByText("Price").className).toContain("text-right");
  });
});

describe("CellMain", () => {
  it("prefers the thumb slot over the icon slot when both are given", () => {
    render(
      <CellMain
        thumb={<Thumb alt="Bright 3-room apartment" />}
        icon={FakeIcon}
        title="Bright 3-room apartment in Chilonzor"
        sub="Chilonzor · 4/9"
      />,
    );
    expect(screen.getByRole("img", { name: "Bright 3-room apartment" })).toBeInTheDocument();
    expect(screen.getByText("Bright 3-room apartment in Chilonzor")).toBeInTheDocument();
    expect(screen.getByText("Chilonzor · 4/9")).toBeInTheDocument();
  });

  it("falls back to the icon slot when there is no thumb", () => {
    const { container } = render(<CellMain icon={FakeIcon} title="Instagram" sub="@javlon.realty" />);
    expect(container.querySelector('[data-testid="fake-icon"]')).not.toBeNull();
    expect(screen.queryByRole("img")).not.toBeInTheDocument();
  });
});

describe("GhostRow", () => {
  it("renders as a single dashed, full-width call to action wired to onClick", async () => {
    const onClick = vi.fn();
    render(
      <table>
        <tbody>
          <GhostRow colSpan={7} onClick={onClick}>
            Create coworker
          </GhostRow>
        </tbody>
      </table>,
    );
    const button = screen.getByRole("button", { name: "Create coworker" });
    expect(button.closest("td")).toHaveAttribute("colspan", "7");
    await userEvent.click(button);
    expect(onClick).toHaveBeenCalledOnce();
  });
});
