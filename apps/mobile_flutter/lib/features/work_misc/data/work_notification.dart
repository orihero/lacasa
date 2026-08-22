/// The client-side shape of one `notifications` row, plus the kind enum the
/// list and its rows switch on for iconography and tap-through routing.
///
/// **Why it lives here and not in `lib/api/models/`.** This is not a wire
/// model — nothing decodes JSON straight into it. `GET /notifications`
/// returns a server row that [LiveNotificationsRepository] reshapes into
/// this type, most notably collapsing the server's `createdAt` timestamp
/// into a display-ready [relativeTime] string. Keeping it beside the
/// repository that produces it, rather than in `lib/api/models/`, is the
/// same split every other feature uses for a screen-facing type that is
/// derived from a wire model rather than being one.
///
/// **History worth knowing if you are cross-referencing older code.** These
/// two declarations used to sit in `lib/shared/fixtures/work_seed_data.dart`
/// alongside the Work tab's hand-written seed rows, and the class was called
/// `WorkNotificationFixture` — a name that made sense when the only thing
/// constructing it was a bundled fixture repository. It never was
/// fixture-only in practice: [LiveNotificationsRepository] constructs it for
/// every real notification the API returns, and `notifications_screen.dart`
/// and `notification_row.dart` render it. When the fixture repositories and
/// their seed data were deleted, these types were the part of that file that
/// was never mock data, so they moved here and lost the misleading suffix.
library;

/// What happened, which decides the row's leading icon and where a tap goes
/// (see `notification_row.dart` and `notifications_screen.dart`).
enum WorkNotificationKind { lead, publish, sold, coworkerActivity }

/// One row of the notifications list.
class WorkNotification {
  final String id;
  final WorkNotificationKind kind;
  final String title;

  /// Display-ready relative-time string ("2 min ago", "Yesterday", ...),
  /// formatted once by [LiveNotificationsRepository] at fetch time from the
  /// server's `createdAt` rather than carried as a [DateTime] the row would
  /// re-derive the same string from on every rebuild. That formatting needs
  /// a resolved `AppLocalizations`, which is why
  /// `notifications_repository_provider.dart` looks one up from the current
  /// [Locale] before constructing the repository — see that provider's
  /// comment.
  final String relativeTime;
  final bool unread;

  /// The id this notification's tap-through target needs — a lead id, an ad
  /// id, or a coworker id, depending on [kind]. `null` for a kind with no
  /// natural target id, in which case the row renders as non-tappable.
  final String? targetId;

  const WorkNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.relativeTime,
    required this.unread,
    required this.targetId,
  });
}
