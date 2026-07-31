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
    agentId: user.agentId,
    tgChatIds: (tgChatIds ?? user.tgChatIds ?? []).map(Number),
    igAccounts,
    igAssistConsentAt: user.igAssistConsentAt ?? null,
  };
}
