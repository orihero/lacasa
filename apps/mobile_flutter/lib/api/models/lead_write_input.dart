/// `POST /api/leads` / `PATCH /api/leads/:id` request body — every field is
/// optional on both verbs server-side (`parseLeadInput` just coerces
/// whatever is present; there is no zod validation on this route at all,
/// see the API contract survey). One class for both verbs, same reasoning
/// as `AdWriteInput` — every field wrapped in [OptionalField] so `PATCH`
/// only touches keys the caller actually mentions.
///
/// **`status` has no validation server-side** — an unrecognized value
/// silently becomes `"new"` (`LEAD_STATUS[body.status] ?? "NEW"`), so a
/// caller passing [LeadStatus.unknown] here would silently create/reset a
/// `new` lead rather than erroring. Never pass [LeadStatus.unknown]
/// through [status] — screens should only ever offer the 5 real statuses.
library;

import 'enums.dart';
import 'optional_field.dart';

class LeadWriteInput {
  final OptionalField<String>? fullName;
  final OptionalField<String>? phone;
  final OptionalField<String?>? email;
  final OptionalField<double?>? budget;

  /// "Interest" in console's UI copy.
  final OptionalField<String?>? comment;

  /// Notes from an interaction — written by `kanban-move-sheet` alongside a
  /// move into `rejected`/`accepted`. Never touched by a plain field edit
  /// that doesn't also change [status].
  final OptionalField<String?>? conversationComment;
  final OptionalField<LeadStatus>? status;
  final OptionalField<String?>? source;

  /// Written alongside [status] `= LeadStatus.needToCallBack` by
  /// `kanban-move-sheet` — see the model's own doc comment for why this is
  /// a plain ISO string on the wire, not `{seconds}`.
  final OptionalField<DateTime?>? callbackDate;
  final OptionalField<bool>? active;

  const LeadWriteInput({
    this.fullName,
    this.phone,
    this.email,
    this.budget,
    this.comment,
    this.conversationComment,
    this.status,
    this.source,
    this.callbackDate,
    this.active,
  });

  Map<String, Object?> toJson() => {
    ...optionalEntry('fullName', fullName),
    ...optionalEntry('phone', phone),
    ...optionalEntry('email', email),
    ...optionalEntry('budget', budget),
    ...optionalEntry('comment', comment),
    ...optionalEntry('conversationComment', conversationComment),
    ...optionalEntry(
      'status',
      status == null ? null : OptionalField(status!.value.wire),
    ),
    ...optionalEntry('source', source),
    ...optionalEntry(
      'callbackDate',
      callbackDate == null
          ? null
          : OptionalField(callbackDate!.value?.toIso8601String()),
    ),
    ...optionalEntry('active', active),
  };
}
