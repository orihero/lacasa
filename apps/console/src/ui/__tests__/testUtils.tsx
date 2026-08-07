/**
 * Re-exports the shared `render()` workaround — see @/test/render's own file
 * header for the full root-cause writeup (the workspace-wide react/react-dom
 * hoisting conflict that makes @testing-library/react's own `render()` throw
 * inside apps/console). Kept as a local `testUtils.tsx` per folder, not a
 * direct `@/test/render` import at every call site, so a future screen that
 * needs to layer on its own additional setup (see
 * screens/coworkers/__tests__/testUtils.tsx's `configure()` addition) has
 * one obvious place to do it without touching every test file's imports.
 */
export { render } from "@/test/render";
