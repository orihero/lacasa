/**
 * Re-exports the shared `render()` workaround — see @/test/render's own file
 * header for the full root-cause writeup (the workspace-wide react/react-dom
 * hoisting conflict that makes @testing-library/react's own `render()` throw
 * inside apps/console).
 */
export { render } from "@/test/render";
