// LLM field-mapping for extension-assisted cross-posting (docs/07 §3.3).
// The model only ever returns data (a field map) under a strict JSON schema —
// never code. The executor in the extension interprets it with a fixed action
// vocabulary and independently refuses submit/publish controls.
import Anthropic from "@anthropic-ai/sdk";
import { config } from "./config.js";

const MODEL = config.LLM_MODEL;

const FIELD_MAP_SCHEMA = {
  type: "object",
  properties: {
    categoryClick: {
      anyOf: [
        { type: "null" },
        {
          type: "object",
          properties: {
            ref: { type: "string" },
            label: { type: "string" },
          },
          required: ["ref", "label"],
          additionalProperties: false,
        },
      ],
    },
    fields: {
      type: "array",
      items: {
        type: "object",
        properties: {
          ref: { type: "string" },
          action: {
            type: "string",
            enum: ["set-value", "select-option", "click-radio"],
          },
          value: { type: "string" },
          confidence: { type: "number" },
        },
        required: ["ref", "action", "value", "confidence"],
        additionalProperties: false,
      },
    },
    unresolved: {
      type: "array",
      items: {
        type: "object",
        properties: {
          ref: { type: "string" },
          reason: { type: "string" },
          suggestedAdField: { anyOf: [{ type: "null" }, { type: "string" }] },
        },
        required: ["ref", "reason", "suggestedAdField"],
        additionalProperties: false,
      },
    },
    confidence: { type: "number" },
  },
  required: ["categoryClick", "fields", "unresolved", "confidence"],
  additionalProperties: false,
};

const CHANNEL_GUIDANCE = {
  olx: `The snapshot comes from the ad-posting form on OLX.uz (Russian/Uzbek UI).
Match the listing's structured fields to the form fields: title, category tree
(Недвижимость → Квартиры → Продажа/Аренда etc.), rooms ("Комнаты"), area
("Общая площадь"), floor/storeys ("Этаж"/"Этажность"), furniture ("Мебель"),
repair state ("Ремонт"), price and currency, city/district, description.
Write the description in the same language the listing uses.`,
  instagram: `The snapshot comes from Instagram's web create-post composer.
Usually the only text field is the caption ("Write a caption..."). For the
caption field, WRITE a compelling real-estate Instagram caption yourself from
the listing data: an attention-grabbing first line, key facts (rooms, area,
floor, district/city, price), emoji used tastefully, a call to action to DM,
and 5-10 relevant hashtags (reuse the listing's hashtags when present).
Match the language of the listing description.`,
};

// Factory instead of a module singleton: app.js constructs one instance at
// boot and threads it through req.ctx.llm, so tests can substitute a fake
// client without a real Anthropic API key or network call.
export function createLlmClient() {
  const configured = config.LLM_CONFIGURED;
  const client = configured ? new Anthropic({ apiKey: config.ANTHROPIC_API_KEY }) : null;

  return {
    configured,
    mapFields: (args) => mapFields(client, configured, args),
  };
}

/**
 * Map a DOM snapshot of a posting form to concrete field actions.
 * @param {Anthropic|null} client
 * @param {boolean} configured
 * @param {object} args
 * @param {"olx"|"instagram"} args.channel
 * @param {object} args.ad        structured listing fields (title, price, rooms, ...)
 * @param {string} args.step      which form step the snapshot belongs to
 * @param {Array}  args.snapshot  FieldNode | CategoryStepNode array from the extension
 */
async function mapFields(client, configured, { channel, ad, step, snapshot }) {
  // Without a key the SDK throws "Could not resolve authentication method",
  // which the generic error handler flattens into "Internal server error" —
  // the extension then just says autofill stopped, with no clue why.
  if (!configured) {
    const err = new Error("ANTHROPIC_API_KEY is not set on the server — AI field-mapping and caption writing are disabled");
    err.code = "llm_unconfigured";
    throw err;
  }

  const system = `You map real-estate listing data onto a live web form.
You receive (a) the listing's structured fields and (b) an accessibility-tree
snapshot of the current form step. Each snapshot node has a "ref" you must use
to address it.

Rules:
- Only use refs that exist in the snapshot.
- action "set-value" types text into an input/textarea; "select-option" picks a
  <select> option by its visible text; "click-radio" clicks a radio/toggle/
  custom-widget option.
- For a "category-step" node, pick the option whose label best matches the
  listing and return it as categoryClick (ref + exact label). Otherwise
  categoryClick must be null.
- NEVER target anything that looks like a final submit/publish/share control
  ("Опубликовать", "Publish", "Joylashtirish", "Share", "Поделиться") — leave
  such elements alone even if they appear in the snapshot.
- Give each action a confidence between 0 and 1. If you cannot confidently map
  a form field that clearly needs a value, list it under unresolved with a
  short reason instead of guessing.
- "confidence" at the top level is your overall confidence for this step.

${CHANNEL_GUIDANCE[channel] ?? ""}`;

  const response = await client.beta.messages.create({
    model: MODEL,
    max_tokens: 8192,
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
    system,
    output_config: { format: { type: "json_schema", schema: FIELD_MAP_SCHEMA } },
    messages: [
      {
        role: "user",
        content:
          `Form step: ${step}\n\n` +
          `Listing data:\n${JSON.stringify(ad, null, 2)}\n\n` +
          `Form snapshot:\n${JSON.stringify(snapshot)}`,
      },
    ],
  });

  if (response.stop_reason === "refusal") {
    const err = new Error("LLM declined to map this form");
    err.code = "llm_refusal";
    throw err;
  }

  const text = response.content.find((b) => b.type === "text")?.text;
  if (!text) {
    const err = new Error("LLM returned no field map");
    err.code = "llm_empty";
    throw err;
  }
  return JSON.parse(text);
}
