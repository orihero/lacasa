import { screen } from "@testing-library/dom";
import { describe, expect, it } from "vitest";
import { Tag, type Tone } from "../Tag";
import { render } from "./testUtils";

describe("Tag", () => {
  it("maps every tone to its own bg/text token pairing", () => {
    const cases: ReadonlyArray<[Tone, string, string]> = [
      ["ok", "bg-ok-soft", "text-ok"],
      ["warn", "bg-warn-soft", "text-warn"],
      ["err", "bg-err-soft", "text-err"],
      ["info", "bg-info-soft", "text-info"],
      ["mute", "bg-mute-soft", "text-mute"],
      ["accent", "bg-accent-tint", "text-accent-text"],
    ];
    for (const [tone, bg, text] of cases) {
      const { unmount } = render(<Tag tone={tone}>Label</Tag>);
      const el = screen.getByText("Label");
      expect(el.className).toContain(bg);
      expect(el.className).toContain(text);
      unmount();
    }
  });

  it("defaults to the mute tone when none is given", () => {
    render(<Tag>Default</Tag>);
    expect(screen.getByText("Default").className).toContain("bg-mute-soft");
  });

  it("renders the dot indicator only when asked", () => {
    const { rerender } = render(<Tag tone="ok">Row</Tag>);
    expect(screen.queryByText("Row")?.querySelector('[aria-hidden="true"]')).toBeNull();

    rerender(
      <Tag tone="ok" dot>
        Row
      </Tag>,
    );
    expect(screen.getByText("Row").querySelector('[aria-hidden="true"]')).not.toBeNull();
  });
});
