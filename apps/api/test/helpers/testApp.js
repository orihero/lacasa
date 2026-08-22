import { createApp } from "../../src/app.js";

// Hand-rolled fakes for the ctx seam — no vi.mock() module interception
// anywhere in this codebase. req.ctx.prisma/minio/llm are plain injected
// values, so a fake object is all a test needs; there is nothing to
// intercept.

// Proxies any model (prisma.user, prisma.ad, ...) to methods that reject by
// default, so a test that exercises an un-stubbed query fails loudly instead
// of silently returning undefined. $queryRaw/$transaction are real enough to
// support the health check and the publish/reassign transaction shape.
export function createFakePrisma(overrides = {}) {
  const modelProxy = () =>
    new Proxy(
      {},
      {
        get: (_t, prop) => {
          if (typeof prop !== "string") return undefined;
          return async () => {
            throw new Error(`fake prisma: no stub for .${prop}() — pass it in overrides`);
          };
        },
      },
    );

  const base = {
    async $queryRaw() {
      return [{ "?column?": 1 }];
    },
    async $transaction(arg) {
      return Array.isArray(arg) ? Promise.all(arg) : arg(base);
    },
  };

  return new Proxy(
    { ...base, ...overrides },
    {
      get: (target, prop) => (prop in target ? target[prop] : modelProxy()),
    },
  );
}

export function createFakeMinio(overrides = {}) {
  return {
    async presignedPutObject() {
      return "https://fake-minio.test/upload";
    },
    async removeObject() {},
    ...overrides,
  };
}

export function createFakeLlm(overrides = {}) {
  return {
    configured: true,
    async mapFields() {
      return { categoryClick: null, fields: [], unresolved: [], confidence: 1 };
    },
    ...overrides,
  };
}

// Builds the app with a fully fake ctx — no real database, object storage,
// or LLM connection. Pass { prisma, minio, llm } to override any of them
// with test-specific stubs.
export function buildTestApp({ prisma, minio, llm } = {}) {
  return createApp({
    prisma: prisma ?? createFakePrisma(),
    minio: minio ?? createFakeMinio(),
    llm: llm ?? createFakeLlm(),
  });
}
