// Six agents worked this tree concurrently; two of them (reviewService.js,
// statisticsService.js) each independently re-derived the same 5-line
// "attach status+code to an Error" helper that adService.js and
// publishService.js already carry locally. Two independent local copies is
// this codebase's deliberate, pre-existing convention (see adService.js's
// own comment on the pattern) -- small enough that a shared module wasn't
// worth it. Four copies is no longer that: it's the same function drifting
// toward four places that could each silently diverge. This is the shared
// home for every *new* consumer from here on; adService.js and
// publishService.js keep their own local copies exactly as they were
// (reconciliation should not rewrite code those agents already shipped and
// tested for a purely cosmetic reason).
export function httpError(status, code, message) {
  const err = new Error(message);
  err.status = status;
  err.code = code;
  return err;
}
