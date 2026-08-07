import { describe, expect, it, vi } from "vitest";
import { createRateLimiter, rateLimitMiddleware } from "../../src/lib/rateLimiter.js";

describe("createRateLimiter", () => {
  it("allows up to `max` calls per key within the window, then blocks", () => {
    const check = createRateLimiter({ windowMs: 60_000, max: 3 });
    expect(check("a").allowed).toBe(true);
    expect(check("a").allowed).toBe(true);
    expect(check("a").allowed).toBe(true);
    const blocked = check("a");
    expect(blocked.allowed).toBe(false);
    expect(blocked.retryAfterMs).toBeGreaterThan(0);
  });

  it("tracks separate keys independently", () => {
    const check = createRateLimiter({ windowMs: 60_000, max: 1 });
    expect(check("a").allowed).toBe(true);
    expect(check("b").allowed).toBe(true);
    expect(check("a").allowed).toBe(false);
    expect(check("b").allowed).toBe(false);
  });

  it("allows again once the window has passed", () => {
    vi.useFakeTimers();
    try {
      const check = createRateLimiter({ windowMs: 1000, max: 1 });
      expect(check("a").allowed).toBe(true);
      expect(check("a").allowed).toBe(false);
      vi.advanceTimersByTime(1001);
      expect(check("a").allowed).toBe(true);
    } finally {
      vi.useRealTimers();
    }
  });

  it("two separate createRateLimiter() instances never share state", () => {
    const first = createRateLimiter({ windowMs: 60_000, max: 1 });
    const second = createRateLimiter({ windowMs: 60_000, max: 1 });
    expect(first("a").allowed).toBe(true);
    expect(second("a").allowed).toBe(true);
  });
});

describe("rateLimitMiddleware", () => {
  function fakeReqRes(ip = "1.2.3.4") {
    const req = { ip };
    const res = {
      statusCode: null,
      body: null,
      headers: {},
      set(name, value) {
        this.headers[name] = value;
        return this;
      },
      status(code) {
        this.statusCode = code;
        return this;
      },
      json(body) {
        this.body = body;
        return this;
      },
    };
    return { req, res };
  }

  it("calls next() while under the limit", () => {
    const middleware = rateLimitMiddleware({ windowMs: 60_000, max: 2 });
    const { req, res } = fakeReqRes();
    const next = vi.fn();
    middleware(req, res, next);
    expect(next).toHaveBeenCalledOnce();
    expect(res.statusCode).toBeNull();
  });

  it("answers 429 with the error envelope and a Retry-After header once the limit is hit", () => {
    const middleware = rateLimitMiddleware({ windowMs: 60_000, max: 1, code: "rate_limited", message: "slow down" });
    const { req, res } = fakeReqRes();
    middleware(req, res, vi.fn());

    const next = vi.fn();
    middleware(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(429);
    expect(res.body).toEqual({ error: { code: "rate_limited", message: "slow down" } });
    expect(res.headers["Retry-After"]).toBeDefined();
  });

  it("keys by IP by default, so two different callers get independent budgets", () => {
    const middleware = rateLimitMiddleware({ windowMs: 60_000, max: 1 });
    const a = fakeReqRes("1.1.1.1");
    const b = fakeReqRes("2.2.2.2");
    middleware(a.req, a.res, vi.fn());
    const nextA = vi.fn();
    middleware(a.req, a.res, nextA);
    const nextB = vi.fn();
    middleware(b.req, b.res, nextB);

    expect(nextA).not.toHaveBeenCalled();
    expect(nextB).toHaveBeenCalledOnce();
  });
});
