// Thin re-export: the wire-format enum maps (AD_TYPE, AD_CATEGORY,
// REPAIRMENT, FURNITURE, AD_STAGE, CURRENCY_CODE, LEAD_STATUS, EVENT_STAGE
// and their *_REV inverses) now live in @lacasa/domain/enums, shared with
// apps/web and apps/extension. Re-exporting here keeps every existing
// `from "../lib/enums.js"` importer in this app unchanged.
export * from "@lacasa/domain/enums";
