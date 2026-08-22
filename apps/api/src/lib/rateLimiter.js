// Small dependency-free in-process rate limiter. Added for POST /api/contact
// (docs/04-api-spec.md's "Publishing & contact" section calls it out as
// "rate-limited"), which is the first route in this app with no auth to key
// off of at all -- every other abuse-prone action (OLX_DAILY_CAP,
// IG_ASSIST_DAILY_CAP in publishService.js) is scoped to an authenticated
// agentId instead. No rate-limiting middleware or dependency (e.g.
// express-rate-limit) existed anywhere in apps/api before this file --
// checked package.json and grepped node_modules/.bin before adding it.
//
// This is intentionally NOT distributed: state lives in a plain Map in this
// process's memory. Fine today (src/server.js runs a single Node process,
// no cluster/pm2), but would silently stop enforcing a shared limit the day
// this app runs more than one instance behind a load balancer -- that would
// need a shared store (e.g. Redis) instead, which is out of scope here.

/**
 * Returns a `check(key)` function closed over its own sliding-window Map, so
 * independent limiters (or independent tests) never share state. A window
 * is just an array of request timestamps for that key; old timestamps are
 * trimmed off the front on every check, and an emptied bucket is deleted
 * from the map so long-idle keys don't leak memory forever.
 */
export function createRateLimiter({ windowMs, max }) {
  const buckets = new Map();

  return function check(key) {
    const now = Date.now();
    const windowStart = now - windowMs;

    let bucket = buckets.get(key);
    if (bucket) {
      while (bucket.length && bucket[0] <= windowStart) bucket.shift();
      if (bucket.length === 0) {
        buckets.delete(key);
        bucket = undefined;
      }
    }
    if (!bucket) {
      bucket = [];
      buckets.set(key, bucket);
    }

    if (bucket.length >= max) {
      return { allowed: false, retryAfterMs: bucket[0] + windowMs - now };
    }
    bucket.push(now);
    return { allowed: true };
  };
}

// Express middleware wrapping createRateLimiter. keyFn defaults to the
// caller's IP address -- the only identity a public, unauthenticated route
// has to key a limit off of.
export function rateLimitMiddleware({
  windowMs,
  max,
  keyFn = (req) => req.ip,
  code = "rate_limited",
  message = "Too many requests. Please try again later.",
}) {
  const check = createRateLimiter({ windowMs, max });
  return (req, res, next) => {
    const result = check(keyFn(req));
    if (!result.allowed) {
      res.set("Retry-After", String(Math.max(1, Math.ceil(result.retryAfterMs / 1000))));
      return res.status(429).json({ error: { code, message } });
    }
    next();
  };
}
