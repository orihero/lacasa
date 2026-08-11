import { REALTOR_KIND_REV, REALTOR_STATUS_REV, TEAM_SIZE_REV } from "@lacasa/domain";

// Shapes a Prisma User row into the JSON the frontend's zustand stores
// already expect (role lowercased, `avatar` not `avatarUrl`) so the rest of
// the app — most of which is still Firestore-backed pending later migration
// phases — keeps working unchanged. IG access tokens are no longer sent to
// the client (migration plan E.2); igAccounts carries metadata only.
export function serializeUser(user, { igAccounts = [], tgChatIds } = {}) {
  return {
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    role: user.role.toLowerCase(),
    phoneNumber: user.phoneNumber,
    avatar: user.avatarUrl,
    address: user.address ?? null,
    agentId: user.agentId,
    tgChatIds: (tgChatIds ?? user.tgChatIds ?? []).map(Number),
    igAccounts,
    igAssistConsentAt: user.igAssistConsentAt ?? null,
    realtor: serializeRealtor(user),
  };
}

// Null for a buyer and for a coworker (whose team facts belong to their
// agent), so `user.realtor?.kind === "agency"` is the whole test a client
// needs to decide whether to show the Coworkers screen. Keys are lowercased
// like `role` above, matching @lacasa/domain's wire-format enums.
function serializeRealtor(user) {
  if (!user.realtorKind) return null;
  return {
    kind: REALTOR_KIND_REV[user.realtorKind],
    status: REALTOR_STATUS_REV[user.realtorStatus ?? "NONE"],
    agencyName: user.agencyName ?? null,
    officePhone: user.officePhone ?? null,
    teamSize: user.teamSize ? TEAM_SIZE_REV[user.teamSize] : null,
    appliedAt: user.realtorAppliedAt ?? null,
    decidedAt: user.realtorDecidedAt ?? null,
  };
}
