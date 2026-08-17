/**
 * The regression this file guards is not hypothetical: a screen dereferenced
 * a field the API sends as null, and with no boundary the whole control room
 * unmounted to an empty #root. The assertion that matters is the second one —
 * that something legible is on screen — because a blank admin panel is
 * indistinguishable from an empty queue.
 */
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { screen } from "@testing-library/dom";
import { ErrorBoundary } from "../ErrorBoundary";
import { render } from "@/test/render";

function Boom(): never {
  throw new Error("realtor is null");
}

describe("ErrorBoundary", () => {
  beforeEach(() => {
    // React logs every caught error to console.error on its own, on top of
    // componentDidCatch. Silenced so a passing test doesn't print a stack
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
});
