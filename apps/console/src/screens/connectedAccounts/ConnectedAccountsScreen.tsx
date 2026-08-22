/**
 * ConnectedAccountsScreen — mockups/f/PLAN.md §3.8 (`a-accounts`).
 *
 * PLAN.md §4's known gap list names this screen directly: "No
 * ConnectedAccount model / endpoint." Instagram is the one channel that
 * genuinely has real, per-account backing data despite that — GET
 * /publish/instagram/accounts reads real `AgentIgToken` rows (username +
 * token expiry), and POST /auth/instagram/connect-url + DELETE
 * /auth/instagram/:igUserId are real, working connect/disconnect actions
 * (src/data/useConnectedAccounts.ts).
 *
 * That said, "Connect" completing does not mean publishing from this app
 * will work end to end: apps/api/src/lib/instagram.js requests the
 * `instagram_business_content_publish` scope, an advanced Meta permission
 * that needs Meta App Review before it functions for accounts that aren't
 * registered as testers on the Meta app (see this repo's crosspost
 * implementation notes — App Review for that scope is still pending as of
 * this build). The screen says so next to the action, rather than letting a
 * successful OAuth round-trip imply real publishing already works for every
 * agent.
 *
 * Everything else on this screen is genuinely ungrounded and is treated
 * accordingly, never papered over with a plausible-looking status:
 *  - Telegram renders `AuthUser.tgChatIds`'s *count* only (from
 *    `useAuth()`, populated by GET /auth/me) — PLAN.md §4: "tgChatIds has no
 *    per-channel name field; never fabricate channel names." There is no
 *    endpoint to manage individual channels, so "Manage" is a disabled
 *    button with a title naming the gap, not a link to nowhere.
 *  - YouTube and OLX have no stored connection record at all (no
 *    ConnectedAccount model, no browser-extension bridge this web console
 *    can observe) — PLAN.md §4: "reflects extension/browser-session-
 *    detected state, not a stored ConnectedAccount row (none exists)." Both
 *    render an honest "not tracked" status and a disabled action button.
 *
 * ACCENT DISCIPLINE DEVIATION, reported rather than silently shipped: PLAN.md
 * §1's table names this screen's one accent thing as "YouTube 'Reconnect'
 * (urgent)". That button doesn't exist here — an accent CTA that reconnects
 * nothing (no YouTube endpoint, no stored state to act on) would be exactly
 * the fake-affordance the data-honesty rule prohibits, worse than the
 * disabled button this renders instead. This screen has zero `bg-accent`
 * elements; see this agent's final report for why that's the right call
 * given the real API surface, not an oversight.
 *
 * TWO REVIEW FIXES (adversarial pass, same day): (1) a failed Disconnect call
 * previously reset `pendingDisconnectId` via `onSettled` and showed nothing
 * else — a real disconnect failure (network blip, a 403) was silently
 * swallowed, unlike Connect's error path a few lines below it. Now mirrored:
 * `disconnectInstagram.isError` + `.variables` pin the error message to the
 * row that actually failed. (2) apps/api/src/routes/instagramAuth.js 403s
 * both POST /connect-url and DELETE /:igUserId for any role but AGENT — a
 * COWORKER can reach this screen (routes.tsx has no role gate on it) and was
 * seeing enabled Connect/Disconnect buttons that would fail every time.
 * `canManageInstagram` now disables both with a title, matching the honesty
 * pattern this file already used for YouTube/OLX instead of leaving Instagram
 * as the one exception.
 */
import { useState, type ReactNode } from "react";
import { useAuth } from "@/lib/auth";
import { useInstagramAccounts, useConnectInstagram, useDisconnectInstagram } from "@/data/useConnectedAccounts";
import { formatDateTime } from "@/lib/format";
import { PageHead } from "@/shell/PageHead";
import { Panel, PanelHead } from "@/ui/Panel";
import { Button } from "@/ui/Button";
import { Flag } from "@/ui/Flag";
import { Switch } from "@/ui/Switch";
import { InstagramLogoIcon, LinkSimpleIcon, StorefrontIcon, TelegramLogoIcon, YoutubeLogoIcon } from "@/ui/icons";

const CRUMB = "Console · Team";

export function ConnectedAccountsScreen() {
  const { user } = useAuth();
  const instagramQuery = useInstagramAccounts();
  const connectInstagram = useConnectInstagram();
  const disconnectInstagram = useDisconnectInstagram();
  const [pendingDisconnectId, setPendingDisconnectId] = useState<string | null>(null);

  function openInstagramConnect() {
    connectInstagram.mutate(undefined, {
      onSuccess: (url) => {
        window.open(url, "_blank", "noopener,noreferrer");
      },
    });
  }

  function disconnect(igUserId: string) {
    setPendingDisconnectId(igUserId);
    disconnectInstagram.mutate(igUserId, {
      onSettled: () => setPendingDisconnectId(null),
    });
  }

  const tgChannelCount = user?.tgChatIds?.length ?? 0;
  const instagramAccounts = instagramQuery.data ?? [];
  // apps/api/src/routes/instagramAuth.js 403s both POST /connect-url and
  // DELETE /:igUserId for any role but AGENT ("Only agents can
  // connect/disconnect an Instagram account") — a COWORKER can reach this
  // screen (routes.tsx has no role gate) and would otherwise see enabled
  // buttons that are guaranteed to fail server-side every time.
  const canManageInstagram = user?.role === "AGENT";
  const instagramManageTitle = canManageInstagram
    ? undefined
    : "Only the agent account can connect or disconnect Instagram — this is a coworker account.";

  return (
    <>
      <PageHead crumb={CRUMB} title="Connected accounts" />

      <div className="grid grid-cols-[1fr_330px] items-start gap-[26px]">
        <Panel>
          <PanelHead title="Connected accounts" sub="Status switches are read-only indicators" />

          <Flag>
            There is no <span className="font-mono">ConnectedAccount</span> model or endpoint yet (mockups/f/
            PLAN.md §4) — Telegram shows a channel count only (no per-channel name field to show), and YouTube/OLX
            have no stored connection record at all, so their status below is honestly &quot;not tracked&quot;
            rather than a guess.
          </Flag>

          <div className="flex flex-col gap-2.5">
            <div className="flex items-start gap-3 rounded-input border border-hairline bg-pill px-3.5 py-3">
              <InstagramLogoIcon size={19} weight="fill" className="mt-2.5 shrink-0 text-ink-2" />
              <div className="min-w-0 flex-1">
                <b className="block text-body font-semibold text-ink">Instagram</b>
                {instagramQuery.isLoading ? (
                  <p className="mt-0.5 text-caption text-ink-2">Loading…</p>
                ) : instagramQuery.isError ? (
                  <p className="mt-0.5 text-caption text-err">Couldn&apos;t load connected accounts.</p>
                ) : instagramAccounts.length === 0 ? (
                  <p className="mt-0.5 text-caption text-ink-2">Not connected</p>
                ) : (
                  <ul className="mt-1.5 flex flex-col gap-2">
                    {instagramAccounts.map((account) => (
                      <li key={account.igUserId} className="flex flex-col gap-1">
                        <div className="flex items-center gap-3">
                          <Switch checked readOnly label={`Instagram ${account.username ?? account.igUserId} connected`} />
                          <span className="min-w-0 flex-1 truncate text-caption text-ink-2">
                            {account.username ? `@${account.username}` : account.igUserId}
                            {account.expiresAt ? ` · token refreshes ${formatDateTime(account.expiresAt)}` : null}
                          </span>
                          <Button
                            onClick={() => disconnect(account.igUserId)}
                            disabled={
                              !canManageInstagram ||
                              (pendingDisconnectId === account.igUserId && disconnectInstagram.isPending)
                            }
                            title={instagramManageTitle}
                          >
                            {pendingDisconnectId === account.igUserId && disconnectInstagram.isPending
                              ? "Disconnecting…"
                              : "Disconnect"}
                          </Button>
                        </div>
                        {/* disconnectInstagram is one shared mutation across every row in
                            this list — `variables` pins the error to the account that
                            actually failed, not to whichever row rendered last. Previously
                            unhandled: a failed disconnect reset silently with zero feedback. */}
                        {disconnectInstagram.isError && disconnectInstagram.variables === account.igUserId ? (
                          <p className="text-caption text-err">{disconnectInstagram.error.message}</p>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                )}
                {connectInstagram.isError ? (
                  <p className="mt-1 text-caption text-err">{connectInstagram.error.message}</p>
                ) : null}
                <p className="mt-1.5 text-caption text-warn-text">
                  Publishing needs Meta&apos;s <span className="font-mono">instagram_business_content_publish</span>{" "}
                  permission, which is still awaiting Meta App Review — connecting may only complete for accounts
                  registered as testers on the Meta app until that review clears.
                </p>
              </div>
              <div className="flex-none">
                <Button
                  variant="dark"
                  onClick={openInstagramConnect}
                  disabled={!canManageInstagram || connectInstagram.isPending || instagramQuery.isLoading}
                  title={instagramManageTitle}
                >
                  {connectInstagram.isPending
                    ? "Opening…"
                    : instagramAccounts.length > 0
                      ? "Connect another"
                      : "Connect"}
                </Button>
              </div>
            </div>

            <AccountRow
              icon={<TelegramLogoIcon size={19} weight="fill" className="text-ink-2" />}
              name="Telegram"
              status={tgChannelCount > 0 ? `${tgChannelCount} channel${tgChannelCount === 1 ? "" : "s"} connected` : "Not connected"}
              connected={tgChannelCount > 0}
              actionLabel="Manage"
              actionDisabledTitle="No endpoint manages individual Telegram channels yet — this reflects tgChatIds's count only."
            />

            <AccountRow
              icon={<YoutubeLogoIcon size={19} weight="fill" className="text-ink-2" />}
              name="YouTube"
              status="Not tracked by this console"
              connected={false}
              actionLabel="Reconnect"
              actionDisabledTitle="No ConnectedAccount record and no YouTube endpoint exist yet — there is nothing real to reconnect."
            />

            <AccountRow
              icon={<StorefrontIcon size={19} weight="fill" className="text-ink-2" />}
              name="OLX"
              status="Not tracked by this console — requires the browser extension"
              connected={false}
              actionLabel="Settings"
              actionDisabledTitle="OLX connection state lives in the browser extension, not a server record this console can read."
            />
          </div>
        </Panel>

        <Panel>
          <PanelHead title="Extension" />
          <p className="text-small leading-[1.6] text-ink-2">
            The La Casa browser extension fills OLX and Instagram forms for you, then hands control back so you
            click Publish yourself. It never posts on your behalf.
          </p>
          <Button
            variant="dark"
            className="mt-3.5 w-full justify-center"
            disabled
            title="This console has no way to detect or open the extension's own settings page — that lives in the browser, not this server."
          >
            <LinkSimpleIcon size={14} />
            Open extension settings
          </Button>
        </Panel>
      </div>
    </>
  );
}

function AccountRow({
  icon,
  name,
  status,
  connected,
  actionLabel,
  actionDisabledTitle,
}: {
  icon: ReactNode;
  name: string;
  status: string;
  connected: boolean;
  actionLabel: string;
  actionDisabledTitle: string;
}) {
  return (
    <div className="flex items-center gap-3 rounded-input border border-hairline bg-pill px-3.5 py-3">
      {icon}
      <div className="min-w-0 flex-1">
        <b className="block text-body font-semibold text-ink">{name}</b>
        <span className="block text-caption text-ink-2">{status}</span>
      </div>
      <Switch checked={connected} readOnly label={`${name} ${connected ? "connected" : "not connected"}`} />
      <Button disabled title={actionDisabledTitle}>
        {actionLabel}
      </Button>
    </div>
  );
}
