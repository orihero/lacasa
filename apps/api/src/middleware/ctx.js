// Attaches the request-scoped dependency context — prisma, minio, llm — that
// every route and middleware reads as req.ctx.* instead of importing module
// singletons. This is the seam that makes supertest(app) usable against a
// hand-rolled fake ctx (test/helpers/testApp.js) with no real database,
// object storage, or LLM connection, and without vi.mock() module
// interception anywhere.
export function attachCtx(ctx) {
  return function ctxMiddleware(req, _res, next) {
    req.ctx = ctx;
    next();
  };
}
