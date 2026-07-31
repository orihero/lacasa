import { describe, expect, it } from "vitest";
import supertest from "supertest";
import { randomUUID } from "node:crypto";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";

// Real Postgres (test/integration/helpers/db.js), fake MinIO/LLM — auth
// never touches either, but createApp() always needs a full ctx.
const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

function uniqueEmail(label) {
  return `${label}-${randomUUID()}@example.test`;
}

describe("POST /api/auth/register", () => {
  it("hashes the password, creates a USER row, and returns a usable token", async () => {
    const email = uniqueEmail("register");
    const res = await supertest(app)
      .post("/api/auth/register")
      .send({ fullName: "Ada Lovelace", email, password: "s3cret-pass" });

    expect(res.status).toBe(201);
    expect(res.body.token).toBeTruthy();
    // serializeUser.js lowercases role for the frontend's zustand stores.
    expect(res.body.user).toMatchObject({ email, fullName: "Ada Lovelace", role: "user" });
    expect(res.body.user.passwordHash).toBeUndefined();
  });

  it("rejects a duplicate email with 409", async () => {
    const email = uniqueEmail("dup");
    await supertest(app).post("/api/auth/register").send({ fullName: "First", email, password: "s3cret-pass" });

    const res = await supertest(app)
      .post("/api/auth/register")
      .send({ fullName: "Second", email, password: "s3cret-pass" });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe("email_taken");
  });

  it("rejects an invalid payload with 400", async () => {
    const res = await supertest(app)
      .post("/api/auth/register")
      .send({ fullName: "", email: "not-an-email", password: "x" });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });
});

describe("POST /api/auth/login", () => {
  it("returns a token for correct credentials and 401 for a wrong password", async () => {
    const email = uniqueEmail("login");
    await supertest(app).post("/api/auth/register").send({ fullName: "Login Test", email, password: "correct-horse" });

    const ok = await supertest(app).post("/api/auth/login").send({ email, password: "correct-horse" });
    expect(ok.status).toBe(200);
    expect(ok.body.token).toBeTruthy();

    const wrongPassword = await supertest(app).post("/api/auth/login").send({ email, password: "wrong" });
    expect(wrongPassword.status).toBe(401);

    const unknownEmail = await supertest(app)
      .post("/api/auth/login")
      .send({ email: uniqueEmail("unknown"), password: "whatever" });
    expect(unknownEmail.status).toBe(401);
  });
});

describe("GET /api/auth/me", () => {
  it("returns the current user for a valid token and 401 for none/invalid", async () => {
    const email = uniqueEmail("me");
    const register = await supertest(app)
      .post("/api/auth/register")
      .send({ fullName: "Me Test", email, password: "s3cret-pass" });

    const authed = await supertest(app).get("/api/auth/me").set("Authorization", `Bearer ${register.body.token}`);
    expect(authed.status).toBe(200);
    expect(authed.body.user.email).toBe(email);

    const anon = await supertest(app).get("/api/auth/me");
    expect(anon.status).toBe(401);

    const bogus = await supertest(app).get("/api/auth/me").set("Authorization", "Bearer not-a-real-token");
    expect(bogus.status).toBe(401);
  });
});
