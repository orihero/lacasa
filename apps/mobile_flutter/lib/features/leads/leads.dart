/// Barrel for `lib/features/leads/` — `lib/navigation/app_router.dart`
/// needs [LeadsListScreen]/[LeadsKanbanScreen]/[CreateLeadScreen] to wire
/// `RoutePaths.workLeads`/`workLeadsKanban`/`workCreateLead`.
///
/// [showLeadDetailSheet] is exported here too — it is this feature's one
/// export another *feature* imports directly rather than through a route:
/// `work_misc`'s `NotificationsScreen` calls it for its "lead notification
/// → lead-detail" tap target (contract §3.4).
///
/// `showKanbanMoveSheet` (`widgets/kanban_move_sheet.dart`) is **not**
/// exported here — its one and only caller is this feature's own
/// `leads_kanban_screen.dart` (contract §3.3), so it stays an internal
/// implementation detail rather than a public surface.
library;

export 'widgets/create_lead_screen.dart';
export 'widgets/lead_detail_sheet.dart';
export 'widgets/leads_kanban_screen.dart';
export 'widgets/leads_list_screen.dart';
