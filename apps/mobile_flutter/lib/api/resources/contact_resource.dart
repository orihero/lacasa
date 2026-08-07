/// `POST /api/contact` — the public contact form (`apps/api/src/routes/
/// contact.js`), relayed server-side to the office Telegram chat. Reached
/// from `contact-sheet` (SCREENS.md §3.11), itself opened by
/// `listing-detail`'s "Submit an application" CTA.
///
/// Deliberately unauthenticated, like `GET /ads` — there is no signed-in
/// user on the buyer side of this flow. That also makes it the one
/// abuse-exposed route in this client, so the server rate-limits it by IP
/// (5/minute) and length-bounds every field with `contactSchema`
/// (`packages/domain/src/schemas/contact.ts`). Nothing here retries a
/// rejected submit — a `rateLimited` answer means wait, not try harder.
library;

import '../api_client.dart';

/// The `POST /api/contact` request body, matching `contactSchema` field for
/// field. Construct it through the screen's own validation
/// (`features/contact/`), not from raw user input — the server's 400 is a
/// backstop, not the primary check.
class ContactRequest {
  const ContactRequest({
    required this.name,
    required this.phone,
    this.message = '',
  });

  /// 1–120 characters after trimming, server-side.
  final String name;

  /// `^\+998\d{9}$` — the same pattern [Formatters.isValidUzPhone]
  /// (`shared/formatters/formatters.dart`) checks client-side.
  final String phone;

  /// Optional; the server defaults it to `''` when omitted. See
  /// `features/contact/widgets/contact_sheet.dart` for why this client
  /// caps it at 200 characters rather than the schema's own 2000.
  final String message;

  Map<String, Object?> toJson() => {
    'name': name,
    'phone': phone,
    'message': message,
  };
}

class ContactResource {
  final ApiClient _client;

  const ContactResource(this._client);

  /// `POST /api/contact`. Answers 202 with `{ok: true}` on success — there
  /// is nothing to return, so this resolves to `void`.
  ///
  /// Throws [ApiErrorException] with:
  /// - `code: validation` (400) — a field the server rejected;
  /// - `code: rateLimited` (429) — more than 5 submits from this IP in a
  ///   minute;
  /// - `code: contactUnconfigured` (503) — the server has no Telegram chat
  ///   configured, i.e. nobody would ever receive this message. Distinct
  ///   from a transport failure and worth different copy: retrying cannot
  ///   help.
  /// - `code: contactRelayFailed` (502) — Telegram itself refused; a
  ///   later retry genuinely might work.
  Future<void> submit(ContactRequest request) async {
    await _client.request(
      method: 'POST',
      path: '/contact',
      body: request.toJson(),
    );
  }
}
