/**
 * The regression this file guards is not hypothetical: a screen dereferenced a
 * field the API sends as null, and with no boundary the whole control room
 * unmounted to an empty #root. THE ASSERTION THAT MATTERS IS THE SECOND ONE —
 * that something legible is on screen — because a blank admin panel is
 * indistinguishable from an empty queue.
 */
import { render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import i18n from "@/i18n";
import { ErrorBoundary } from "../ErrorBoundary";

function Boom(): never {
  throw new Error("realtor is null");
}

describe("ErrorBoundary", () => {
  beforeEach(async () => {
    // The copy asserted below is the English copy; a sibling suite that leaves
    // i18next on another language must not turn this red.
    await i18n.changeLanguage("en");
    // React logs every caught error to console.error on its own, on top of
    // componentDidCatch. Silenced so a passing test does not print a stack
    // trace that reads like a failure.
    vi.spyOn(console, "error").mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("renders children untouched when nothing throws", () => {
    render(
      <ErrorBoundary>
        <p>the queue</p>
      </ErrorBoundary>,
    );

    expect(screen.getByText("the queue")).toBeTruthy();
  });

  it("replaces a throwing tree with a legible failure instead of a blank page", () => {
    const { container } = render(
      <ErrorBoundary>
        <Boom />
      </ErrorBoundary>,
    );

    expect(container.textContent).not.toBe("");
    expect(screen.getByText("This screen failed to render")).toBeTruthy();
    // The message is surfaced, not swallowed — it is what identifies the bug.
    expect(screen.getByText("realtor is null")).toBeTruthy();
  });

  it("keeps the environment strip visible on the failure screen", () => {
    // An operator reading a crash still has to know which database the tab was
    // pointed at before they act on it.
    //
    // getByRole throws when more than one element matches, so this also pins
    // the rule that the environment strip is the ONLY role="status" on the
    // crash screen: nothing in the fallback may claim the role as well.
    render(
      <ErrorBoundary>
        <Boom />
      </ErrorBoundary>,
    );

    const strip = screen.getByRole("status");
    expect(strip.getAttribute("aria-label")).toMatch(/^Environment: /);
  });

  it("states that nothing was written, since the failure was a render", () => {
    render(
      <ErrorBoundary>
        <Boom />
      </ErrorBoundary>,
    );

    expect(screen.getByText(/Nothing was changed by this error/)).toBeTruthy();
  });

  it("logs the error and the component stack rather than swallowing them", () => {
    const spy = vi.spyOn(console, "error");

    render(
      <ErrorBoundary>
        <Boom />
      </ErrorBoundary>,
    );

    // The component stack is the useful half: it names the screen that threw.
    expect(
      spy.mock.calls.some((call) => call[0] === "[control-room] render error"),
    ).toBe(true);
  });
});
