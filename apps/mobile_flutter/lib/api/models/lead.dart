/// The `Lead` wire shape (`apps/api/src/services/leadService.js#serializeLead`)
/// — the truth for `GET /leads`, `GET /leads/:id`, `POST /leads` and
/// `PATCH /leads/:id`'s responses.
///
/// **Timestamp format is mixed on this one model — read carefully.**
/// [createdAt]/[updatedAt] are the Firestore-style `{seconds}` shape (same
/// as `Ad`, decode via [dateTimeFromWireTimestamp]), but [callbackDate] is a
/// raw JS `Date` serialized as a plain ISO-8601 string — calling
/// [dateTimeFromWireTimestamp] on it throws. This is a genuine server-side
/// inconsistency (documented in the API contract survey), not a client
/// bug — [Lead.fromJson] decodes each field the way its own wire shape
/// actually arrives.
library;

import 'enums.dart';
import 'wire_timestamp.dart';

class Lead {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final double? budget;

  /// "Interest" in console's UI copy — what the lead is looking for.
  final String? comment;

  /// "Note"/"Commit" in kanban-move copy — freeform notes from an
  /// interaction, written when a card moves to `rejected`/`accepted`.
  /// Distinct from [comment]; a move never touches [comment].
  final String? conversationComment;
  final LeadStatus status;
  final String? source;

  /// Set (and read) only meaningfully when [status] is
  /// [LeadStatus.needToCallBack] — see `kanban-move-sheet` (SCREENS.md §34).
  final DateTime? callbackDate;
  final bool active;
  final String agentId;

  /// Empty string (not `null`) when the lead has no coworker — same
  /// empty-string-not-null convention as `Ad.coworkerId`.
  final String coworkerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Lead({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.budget,
    required this.comment,
    required this.conversationComment,
    required this.status,
    required this.source,
    required this.callbackDate,
    required this.active,
    required this.agentId,
    required this.coworkerId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// SCREENS.md §31/§24: due today or already overdue — the shared rule
  /// behind Kanban's red callback pill and Dashboard's "N need a callback
  /// today" sub-label (`countCallbacksDueToday`/`isCallbackDueOrOverdue` in
  /// `apps/console/src/lib/leadHelpers.ts`). `end of today` is computed in
  /// the caller's local time zone, matching console.
  bool get isCallbackDueOrOverdue {
    final due = callbackDate;
    if (due == null) return false;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return !due.isAfter(endOfToday);
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      budget: _toDouble(json['budget']),
      comment: json['comment'] as String?,
      conversationComment: json['conversationComment'] as String?,
      status: LeadStatus.fromWire(json['status'] as String?),
      source: json['source'] as String?,
      callbackDate: _parseIso(json['callbackDate']),
      active: json['active'] as bool? ?? true,
      agentId: json['agentId'] as String? ?? '',
      coworkerId: json['coworkerId'] as String? ?? '',
      createdAt: json['createdAt'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['createdAt'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: json['updatedAt'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['updatedAt'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _parseIso(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
