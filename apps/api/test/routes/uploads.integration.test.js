import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

// MinIO is faked (createFakeMinio) even here: the auth gap this route used
// to have (any anonymous caller could mint a presigned upload URL) is a
// property of the route itself, not of MinIO — no real object storage
// connection is needed to prove requireAuth now guards it.
const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

let user;

beforeAll(async () => {
  user = await createUser(prisma, { role: "USER", email: "uploads-user@example.test" });
});

function presignBody(overrides = {}) {
  return { fileName: "photo.jpg", contentType: "image/jpeg", scope: "ads", ...overrides };
}

describe("POST /api/uploads/presign", () => {
  it("rejects an anonymous caller with 401", async () => {
    const res = await supertest(app).post("/api/uploads/presign").send(presignBody());
    expect(res.status).toBe(401);
  });

  it("rejects a bogus bearer token with 401", async () => {
    const res = await supertest(app)
      .post("/api/uploads/presign")
      .set("Authorization", "Bearer not-a-real-token")
      .send(presignBody());
    expect(res.status).toBe(401);
  });

  it("returns a presigned URL (via the fake MinIO client) for an authenticated caller", async () => {
    const res = await supertest(app)
      .post("/api/uploads/presign")
      .set("Authorization", authHeader(user))
      .send(presignBody());

    expect(res.status).toBe(200);
    expect(res.body.uploadUrl).toBeTruthy();
    expect(res.body.objectKey).toMatch(/^ads\//);
  });

  it("still validates the payload (e.g. rejects an unknown scope) for an authenticated caller", async () => {
    const res = await supertest(app)
      .post("/api/uploads/presign")
      .set("Authorization", authHeader(user))
      .send(presignBody({ scope: "not-a-real-scope" }));
    expect(res.status).toBe(400);
  });
});
