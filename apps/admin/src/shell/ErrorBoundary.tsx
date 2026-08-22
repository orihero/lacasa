/**
 * src/shell/ErrorBoundary — the last line between one bad render and a blank
 * control room.
 *
 * This exists because it already happened: a screen dereferenced
 * `application.realtor.kind` on a row the API legitimately sends with
 * `realtor: null`, and with nothing catching it the whole app unmounted to an
 * empty `#root`. A white screen is the worst possible failure mode HERE
 * specifically — an admin who sees nothing cannot tell "the queue is empty"
 * from "the queue failed to draw", and on a surface whose whole job is
 * deciding who gets agent access those two readings lead to opposite actions.
 *
 * apps/web has no error boundary at all (web-design-contract.md §15.9). That
 * absence is one of the things PRECEDENCE.md explicitly refuses to inherit:
 * the design contract governs how this looks, not whether it exists.
 *
 * Deliberately a class component — `getDerivedStateFromError` /
 * `componentDidCatch` have no hook equivalent — and the one class in this
 * codebase. Its fallback lives in ./CrashFallback because a class cannot call
 * useTranslation().
 *
 * It catches RENDER errors only: not event handlers, not async rejections.
 * Those still surface through react-query's `isError` and @/ui/States'
 * ErrorState, which is where a failed fetch belongs. This is for the bugs that
 * escape that path.
 */
import { Component, type ErrorInfo, type ReactNode } from "react";
import { CrashFallback } from "./CrashFallback";

interface Props {
  children: ReactNode;
}

interface State {
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    // Console, NOT a toast. By the time we are here the tree below is gone, so
    // there is nothing left to toast into — and this app routes no mutation
    // outcome through a toast either (PRECEDENCE.md conflict 5). The component
    // stack is the useful half: it names the screen that threw, which the
    // message alone does not.
    console.error("[control-room] render error", error, info.componentStack);
  }

  private handleReload = (): void => {
    // A full reload rather than clearing `error` back to null: whatever data
    // produced the bad render is still in the react-query cache, so
    // re-rendering the same tree would just throw again. Reloading drops the
    // cache with it.
    window.location.reload();
  };

  render(): ReactNode {
    const { error } = this.state;
    if (!error) return this.props.children;

    return <CrashFallback message={error.message} onReload={this.handleReload} />;
  }
}
