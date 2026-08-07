// Ported from the near-identical `caption` reducers duplicated across
// AdsAdd.tsx (onSubmitIG) and AdsEdit.tsx (onSubmitTG, onSubmitIG) —
// apps/web/src/components/{adsAdd/AdsAdd,adsEdit/AdsEdit}.tsx. All three
// walked `Object.entries(getValues())` into a `"label: value unit\n"`
// caption string for the Telegram/Instagram cross-post preview.
//
// AdsAdd's onSubmitTG additionally hoists the `hashtags` field to the front
// of the caption, unlabeled, instead of formatting it as `hashtags: value`
// like every other field — that behavior is preserved here behind the
// `hoistHashtags` option rather than dropped.
//
// The package owns no i18n strings: callers pass their own `translate`
// (e.g. react-i18next's `t`) to render each field's label.

export interface BuildCaptionOptions {
  /**
   * When true, a `hashtags` entry is prepended to the caption verbatim
   * (no label, no price-unit suffix) instead of being formatted like every
   * other field. Matches AdsAdd.tsx's onSubmitTG behavior.
   */
  hoistHashtags?: boolean;
}

/**
 * Builds a cross-post caption from a form's current values.
 *
 * @param values - the form's `getValues()` result (field name -> value).
 * @param priceType - the currently selected price unit (e.g. "uzs"/"usd"),
 *   appended after the `price` field's value.
 * @param translate - renders a field key to its display label.
 */
export function buildCaption(
  values: Record<string, unknown>,
  priceType: string,
  translate: (key: string) => string,
  options: BuildCaptionOptions = {},
): string {
  const { hoistHashtags = false } = options;

  return Object.entries(values).reduce((result, [key, value]) => {
    if (hoistHashtags && key === 'hashtags') {
      return `${String(value)}\n${result}`;
    }
    const unit = key === 'price' ? priceType : '';
    return `${result}${translate(key)}: ${String(value)} ${unit} \n`;
  }, '');
}
