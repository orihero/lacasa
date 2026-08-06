/**
 * Re-exports the shared `render()` workaround — see @/test/render's own file
 * header for the full root-cause writeup (the workspace-wide react/react-dom
 * hoisting conflict that makes @testing-library/react's own `render()` throw
 * inside apps/console, plus the second, independent @phosphor-icons/react
 * hoisting issue this screen also hits — worked around per-test-file via
 * `vi.mock('@/ui/icons', …)`, not here; see PublishStatusScreen.test.tsx).
 */
export { render } from "@/test/render";
