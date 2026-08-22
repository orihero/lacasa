import type { FieldError, FieldErrorsImpl, Merge } from "react-hook-form";

/**
 * react-hook-form's `errors.someField` is typed as
 * `FieldError | Merge<FieldError, FieldErrorsImpl<any>> | undefined`, none of
 * which are directly renderable as JSX children (the `message` on the merged
 * variant is `unknown`). This narrows it down to the plain string message we
 * actually want to display, for every ad-form field-error site.
 */
export function fieldErrorMessage(
  error: FieldError | Merge<FieldError, FieldErrorsImpl<any>> | undefined,
): string | undefined {
  if (!error) return undefined;
  const { message } = error as { message?: unknown };
  return typeof message === "string" ? message : undefined;
}
