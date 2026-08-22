/// Distinguishes "this field was not provided" from "this field was
/// explicitly set to `null`" — needed for every `PATCH` write in this app's
/// CRM surface (`Ad`, `Lead`, `Coworker`), because the server only touches
/// keys actually present in the JSON body (`apps/api`'s `parseAdInput`/
/// `parseLeadInput`/coworker `updateSchema` all treat a missing key as
/// "leave the column alone"). Dart's own optional-named-parameter default
/// (`null`) cannot express this on its own: a param typed `String? address`
/// defaulting to `null` cannot tell "caller didn't mention address" apart
/// from "caller wants address cleared to null" — both arrive as `null`.
///
/// Wrap any nullable write field in [OptionalField] instead:
/// - Omit the argument entirely (Dart's own default, `null`) → the key is
///   left out of the request body → server leaves the column untouched.
/// - Pass `OptionalField(null)` → the key IS sent, with a JSON `null` value
///   → server clears the column.
/// - Pass `OptionalField(value)` → the key is sent with that value.
///
/// This is the one place this convention lives; every CRM write model
/// (`AdWriteInput`, `LeadWriteInput`, `CoworkerUpdateInput`) reuses it
/// rather than re-deriving the same omit/clear logic per model.
class OptionalField<T> {
  final T value;

  const OptionalField(this.value);
}

/// Map-entry helper: `...optionalEntry('address', address)` — expands to
/// nothing when [field] is `null` (omitted), or to one `key: field.value`
/// entry otherwise (including when `field.value` is itself `null`, the
/// explicit-clear case). Spread at every write-model `toJson()` call site
/// instead of hand-writing the same `if (field != null) 'key': field.value`
/// conditional-entry per field.
Map<String, Object?> optionalEntry<T>(String key, OptionalField<T>? field) {
  if (field == null) return const {};
  return {key: field.value};
}
