/**
 * Re-exports the shared `render()` workaround — see @/test/render's own file
 * header for the full root-cause writeup (the workspace-wide react/react-dom
 * hoisting conflict that makes @testing-library/react's own `render()` throw
 * inside apps/console).
 *
 * This folder's own addition on top of the shared helper: @testing-library/
 * react normally wraps userEvent/fireEvent's DOM dispatch in React's `act`
 * for us; without it in the mix (the same hoisting conflict) that wiring has
 * to be redone by hand, or every click that triggers a setState logs an
 * "update not wrapped in act" warning even though the test itself is
 * correct.
 */
import { act } from "react";
import { configure } from "@testing-library/dom";

configure({
  eventWrapper: (cb) => {
    let result: unknown;
    act(() => {
      result = cb();
    });
    return result;
  },
  asyncWrapper: async (cb) => {
    let result: unknown;
    await act(async () => {
      result = await cb();
    });
    return result;
  },
});

export { render } from "@/test/render";
