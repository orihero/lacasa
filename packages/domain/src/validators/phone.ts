// Ported from the inline `/^\+998\d{9}$/` pattern duplicated across
// CoworkerAdd.jsx, CoworkerUpdate.jsx, LeadAdd.jsx, LeadUpdate.jsx, and
// ProfileSetting.jsx (apps/web/src/components/**) — every phone <input>'s
// react-hook-form `register(..., { pattern: {...} })` call hand-copied the
// same regex and required/pattern message shape.

/** Uzbekistan mobile numbers in +998XXXXXXXXX form (9 digits after the code). */
export const UZ_PHONE_REGEX = /^\+998\d{9}$/;

/** Raw predicate — usable outside of a form (e.g. validating an API payload). */
export function isValidUzPhone(value: string): boolean {
  return UZ_PHONE_REGEX.test(value);
}

/**
 * Shaped like the subset of react-hook-form's `RegisterOptions` the phone
 * fields actually use (`register("phone", phoneValidationRule(...))`), so
 * this package never needs a react-hook-form dependency to produce it.
 */
export interface PhoneValidationRule {
  required: string;
  pattern: { value: RegExp; message: string };
}

/**
 * Builds the react-hook-form validation rule for a required Uzbekistan
 * phone field. Messages are supplied by the caller — this package owns no
 * i18n strings.
 */
export function phoneValidationRule(
  requiredMessage: string,
  invalidMessage: string,
): PhoneValidationRule {
  return {
    required: requiredMessage,
    pattern: { value: UZ_PHONE_REGEX, message: invalidMessage },
  };
}
