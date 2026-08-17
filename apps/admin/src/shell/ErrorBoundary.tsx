/**
 * src/shell/ErrorBoundary — the last line between one bad render and a blank
 * control room.
 *
 * This exists because it already happened: ApplicationsScreen dereferenced
 * `application.realtor.kind` on a row the API legitimately sends with
 * `realtor: null`, and with nothing catching it the whole app unmounted to an
 * empty `#root`. A white screen is the worst possible failure mode HERE
 * specifically — an admin who sees nothing cannot tell "the queue is empty"
 * from "the queue failed to draw", and on a surface whose whole job is
 * deciding who gets agent access, those two readings lead to opposite actions.
 *
 * Deliberately a class component: `componentDidCatch` / `getDerivedStateFrom
 * Error` have no hook equivalent in React 19, so an error boundary is the one
 * place this codebase still writes a class.
 *
 * It catches RENDER errors only — not event handlers, not async rejections.
 * Those still surface through react-query's `isError` and the ErrorState
 * primitive, which is where a failed fetch belongs; this is for the bugs that
 * escape that path.
 */
import { Component, type ErrorInfo, type ReactNode } from "react";
import { EnvStrip } from "./EnvStrip";

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
    // Console, not a toast: by the time we are here the tree below is gone, so
    // there is nothing left to toast into. The component stack is the useful
    // half — it names the screen that threw, which the message alone does not.
    console.error("[control-room] render error", error, info.componentStack);
  }

  private handleReload = (): void => {
    // A full reload rather than clearing `error` back to null: whatever data
    // produced the bad render is still in the react-query cache, so re-rendering
    // the same tree would just throw again. Reloading drops the cache with it.
    window.location.reload();
  };

  render(): ReactNode {
    const { error } = this.state;
    if (!error) return this.props.children;

    return (
      <div className="min-h-screen bg-app text-ink">
        {/* The strip stays even here. An operator reading a crash needs to know
            which database the tab was pointed at before they act on it. */}
        <EnvStrip />
        <div className="mx-auto flex max-w-2xl flex-col gap-4 px-6 py-20">
          <p className="text-tiny uppercase tracking-caps text-err">Control room crashed</p>
          <h1 className="text-h1 tracking-display">This screen failed to render</h1>
          <p className="text-md text-ink-2">
            Nothing was changed by this error — it happened while drawing the page, not while
            saving. Reload to try again. If it repeats, the details below identify the bug.
          </p>
          <pre className="overflow-x-auto rounded-card border border-line bg-sunk p-4 font-mono text-caption text-ink-2">
            {error.message}
          </pre>
          <div>
            <button
              type="button"
              onClick={this.handleReload}
              className="rounded-input bg-acc px-4 py-2 text-body font-medium text-on-acc"
            >
              Reload the control room
            </button>
          </div>
        </div>
      </div>
    );
  }
}
