/**
 * src/lib/labels.test — the guard on the two label maps TypeScript cannot
 * guard.
 *
 * Every other map in ./labels is a `Record<SomeDomainEnumKey, …>`, so adding a
 * member to a @lacasa/domain enum without labelling it is a compile error.
 * `AUDIT_TYPE_*` and `PUBLICATION_STATUS_*` have no such key type — their
 * vocabularies live in apps/api/prisma/schema.prisma's `EventType` and
 * `PublishStatus` enums — so this file reads the schema at test time and
 * asserts the maps cover it.
 *
 * WHY IT MATTERS MORE HERE THAN ANYWHERE ELSE: the audit log is the screen an
 * incident is investigated on. A twelfth `EventType` shipped by the API and
 * unlabelled here would be the row that a new feature's first incident is
 * about, and it would be the row that renders as nothing. `auditTypeLabel`
 * falls back to the raw wire value so such a row is still legible — this test
 * is what stops that fallback from quietly becoming the normal case.
 *
 * The schema is read from disk rather than pasted here, because a copy of the
 * enum in this file would drift with exactly the same silence the test exists
 * to prevent.
 */
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { cwd } from "node:process";
import {
  LEAD_STATUS,
  REALTOR_KIND,
  REALTOR_STATUS,
  TEAM_SIZE,
  USER_ROLE,
} from "@lacasa/domain";
import {
  AUDIT_TYPE_KEYS,
  AUDIT_TYPE_LABEL_KEY,
  AUDIT_TYPE_TONE,
  LEAD_STATUS_LABEL_KEY,
  LEAD_STATUS_ORDER,
  PUBLICATION_STATUS_KEYS,
  PUBLICATION_STATUS_LABEL_KEY,
  REALTOR_KIND_LABEL_KEY,
  REALTOR_KIND_TONE,
  REALTOR_STATUS_LABEL_KEY,
  REALTOR_STATUS_TONE,
  TEAM_SIZE_LABEL_KEY,
  USER_ROLE_LABEL_KEY,
  USER_ROLE_ORDER,
  USER_ROLE_TONE,
  auditTypeLabel,
  auditTypeTone,
  publicationStatusLabel,
  userRoleLabel,
  userRoleTone,
} from "./labels";
import en from "../locales/en.json";
import ru from "../locales/ru.json";
import uz from "../locales/uz.json";

/**
 * Resolved from the working directory rather than from `import.meta.url`:
 * under vitest's jsdom environment `import.meta.url` is not a `file:` URL, so
 * `fileURLToPath` throws on it. Both candidates are listed because vitest runs
 * with the workspace as its cwd (`npm run test -w @lacasa/admin`) and a
 * root-level runner would use the repo root.
 */
function resolveSchemaPath(): string {
  const candidates = [
    resolve(cwd(), "../api/prisma/schema.prisma"),
    resolve(cwd(), "apps/api/prisma/schema.prisma"),
  ];
  const found = candidates.find((candidate) => existsSync(candidate));
  if (!found) {
    throw new Error(`schema.prisma not found — looked in:\n  ${candidates.join("\n  ")}`);
  }
  return found;
}

/**
 * Pulls the members out of one `enum Name { … }` block, dropping the trailing
 * `// comment`s the schema annotates several of them with, and lowercasing to
 * the wire form every serializer on this platform emits.
 */
function readSchemaEnum(source: string, name: string): string[] {
  const match = new RegExp(`enum\\s+${name}\\s*\\{([^}]*)\\}`).exec(source);
  if (!match?.[1]) throw new Error(`enum ${name} not found in schema.prisma`);
  return match[1]
    .split("\n")
    .map((line) => line.replace(/\/\/.*$/, "").trim())
    .filter(Boolean)
    .map((member) => member.toLowerCase());
}

const schema = readFileSync(resolveSchemaPath(), "utf8");
const EVENT_TYPES = readSchemaEnum(schema, "EventType");
const PUBLISH_STATUSES = readSchemaEnum(schema, "PublishStatus");

const LOCALES: Record<string, Record<string, string>> = {
  en: en as Record<string, string>,
  ru: ru as Record<string, string>,
  uz: uz as Record<string, string>,
};

/** A stub `t` — resolvers must not need a real i18next instance. */
const identity = (key: string): string => key;

describe("labels — the schema-backed maps", () => {
  it("reads a non-trivial EventType and PublishStatus out of schema.prisma", () => {
    // If the regex ever silently matched nothing, every assertion below would
    // pass vacuously against an empty list.
    expect(EVENT_TYPES.length).toBeGreaterThan(0);
    expect(PUBLISH_STATUSES.length).toBeGreaterThan(0);
  });

  it("labels every EventType member the API can send", () => {
    expect([...AUDIT_TYPE_KEYS].sort()).toEqual([...EVENT_TYPES].sort());
    for (const type of EVENT_TYPES) {
      expect(
        (AUDIT_TYPE_LABEL_KEY as Record<string, string | undefined>)[type],
        `EventType ${type} has no label key`,
      ).toBeTruthy();
      expect(
        (AUDIT_TYPE_TONE as Record<string, string | undefined>)[type],
        `EventType ${type} has no tone`,
      ).toBeTruthy();
    }
  });

  it("keeps the audit filter's option order equal to the schema's declaration order", () => {
    // The filter reads ad.* → lead.* → olx.* → ig.*, which is the schema's own
    // grouping. Reordering the enum without reordering the filter would shuffle
    // a dropdown an admin scans by prefix.
    expect([...AUDIT_TYPE_KEYS]).toEqual(EVENT_TYPES);
  });

  it("labels every PublishStatus member the API can send", () => {
    expect([...PUBLICATION_STATUS_KEYS].sort()).toEqual([...PUBLISH_STATUSES].sort());
    for (const status of PUBLISH_STATUSES) {
      expect(
        (PUBLICATION_STATUS_LABEL_KEY as Record<string, string | undefined>)[status],
        `PublishStatus ${status} has no label key`,
      ).toBeTruthy();
    }
  });
});

describe("labels — the domain-enum-backed maps", () => {
  // These are compile-errors-in-waiting rather than runtime risks, but the
  // assertion is one line and it fails loudly rather than at the moment an
  // admin is looking at a blank cell.
  it.each([
    ["USER_ROLE", USER_ROLE, USER_ROLE_LABEL_KEY],
    ["REALTOR_STATUS", REALTOR_STATUS, REALTOR_STATUS_LABEL_KEY],
    ["REALTOR_KIND", REALTOR_KIND, REALTOR_KIND_LABEL_KEY],
    ["TEAM_SIZE", TEAM_SIZE, TEAM_SIZE_LABEL_KEY],
    ["LEAD_STATUS", LEAD_STATUS, LEAD_STATUS_LABEL_KEY],
  ])("labels every %s member", (_name, enumMap, labelKeys) => {
    expect(Object.keys(labelKeys).sort()).toEqual(Object.keys(enumMap).sort());
  });

  it("derives the role and lead-status orders from the label maps", () => {
    expect(USER_ROLE_ORDER).toEqual(Object.keys(USER_ROLE_LABEL_KEY));
    expect(LEAD_STATUS_ORDER).toEqual(Object.keys(LEAD_STATUS_LABEL_KEY));
  });

  it("tones every role and realtor status", () => {
    expect(Object.keys(USER_ROLE_TONE).sort()).toEqual(Object.keys(USER_ROLE_LABEL_KEY).sort());
    expect(Object.keys(REALTOR_STATUS_TONE).sort()).toEqual(
      Object.keys(REALTOR_STATUS_LABEL_KEY).sort(),
    );
    expect(Object.keys(REALTOR_KIND_TONE).sort()).toEqual(
      Object.keys(REALTOR_KIND_LABEL_KEY).sort(),
    );
  });
});

describe("labels — the i18n keys they point at", () => {
  const allLabelKeys = [
    ...Object.values(USER_ROLE_LABEL_KEY),
    ...Object.values(REALTOR_STATUS_LABEL_KEY),
    ...Object.values(REALTOR_KIND_LABEL_KEY),
    ...Object.values(TEAM_SIZE_LABEL_KEY),
    ...Object.values(LEAD_STATUS_LABEL_KEY),
    ...Object.values(PUBLICATION_STATUS_LABEL_KEY),
    ...Object.values(AUDIT_TYPE_LABEL_KEY),
  ];

  it.each(Object.keys(LOCALES))("resolves every label key in %s", (locale) => {
    const bundle = LOCALES[locale] ?? {};
    const missing = allLabelKeys.filter((key) => typeof bundle[key] !== "string");
    // A key missing from a locale file renders as the key itself — "roleAgent"
    // in a table cell, which is worse than the English word would have been.
    expect(missing, `missing in ${locale}`).toEqual([]);
  });

  it("keeps the audit type labels identical in all three locales", () => {
    // A log is scanned by prefix ("everything olx.*"). Translating
    // `olx.crosspost_aborted` would destroy that, so these are deliberately
    // untranslated and must stay that way.
    for (const key of Object.values(AUDIT_TYPE_LABEL_KEY)) {
      expect(ru[key as keyof typeof ru]).toBe(en[key as keyof typeof en]);
      expect(uz[key as keyof typeof uz]).toBe(en[key as keyof typeof en]);
    }
  });
});

describe("labels — unknown wire values", () => {
  // PRECEDENCE.md section B: the reference fell back to the raw value on the
  // overview and the audit log but rendered an empty Tag on users and
  // applications. Every lookup falls back now.
  it("falls back to the raw value rather than rendering blank", () => {
    expect(auditTypeLabel(identity, "ad_created")).toBe("auditTypeAdCreated");
    expect(auditTypeLabel(identity, "quantum.entangled")).toBe("quantum.entangled");
    expect(userRoleLabel(identity, "agent")).toBe("roleAgent");
    expect(userRoleLabel(identity, "superadmin")).toBe("superadmin");
    expect(publicationStatusLabel(identity, "shadow_banned")).toBe("shadow_banned");
  });

  it("falls back to the mute tone, which claims nothing", () => {
    expect(auditTypeTone("olx_crosspost_aborted")).toBe("err");
    expect(auditTypeTone("quantum.entangled")).toBe("mute");
    expect(userRoleTone("admin")).toBe("danger");
    expect(userRoleTone("superadmin")).toBe("mute");
  });

  it("renders an absent value as the empty string, for the caller's em dash", () => {
    // null/undefined is not an unknown vocabulary member — it is no value at
    // all, and lib/format's EM_DASH is what a caller renders for that.
    expect(userRoleLabel(identity, null)).toBe("");
    expect(auditTypeLabel(identity, undefined)).toBe("");
    expect(userRoleTone(null)).toBe("mute");
  });
});
