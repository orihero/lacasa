/**
 * Publish status — mockups/f/PLAN.md §3.4, f-console.src.html's `#a-publish`.
 *
 * The prototype depicts one fixed ad (`#a3f21`) and its 4-row channel table;
 * the real endpoint (`GET /publish/ads/:adId/status`) is per-ad, so this
 * screen adds what the prototype didn't need: an ad selector, defaulting to
 * the agent's newest ad (`useMyAds()` already returns newest-first — see
 * apps/api/src/routes/myAds.js's default `orderBy: { createdAt: 'desc' }`)
 * and honouring `?adId=` so My ads' broadcast row-action can deep-link
 * straight to one. The selector keeps the URL in sync either way: an
 * explicit `?adId=` is trusted immediately (no flash of "newest ad" while
 * `useMyAds` is still in flight); once ads load, an id that isn't actually
 * this agent's own quietly falls back to the newest one, and the URL is
 * corrected to match — see `selectedAdId`'s derivation below.
 *
 * "Retry failed" is this screen's one accent CTA (PLAN.md §1) — and it's
 * permanently disabled. apps/api/src/routes/publish.js has no retry
 * endpoint: only /instagram, /instagram/accounts, /instagram/consent,
 * /:channel/map-fields, /:channel/confirm, /reassign and the two status
 * reads. Retrying TG/IG for real means re-invoking their own publish route
 * with the ad's images/caption (not available on this screen), and OLX/
 * YouTube retries are human-in-the-browser flows this console can't trigger
 * at all. Faking the button would violate PLAN.md §4; disabling it with a
 * `title` + `<Flag>` doesn't.
 *
 * `PublishStatusScreen` itself is a thin wrapper around `PublishStatusView`,
 * which takes `navigate`/`searchParams`/`setSearchParams` as props instead
 * of calling `useNavigate`/`useSearchParams` directly. That split is not
 * cosmetic: react-router-dom is hoisted to the workspace root (npm's fix for
 * apps/web pinning React 18 — see the FOUNDATION CONTRACT's react-version
 * concerns), so its hooks run against the wrong React copy under this app's
 * vitest setup and crash on mount ("Cannot read properties of null (reading
 * 'useRef')") independent of anything this screen does — confirmed with a
 * bare `<MemoryRouter>` and zero screen code involved. Threading the three
 * router primitives through as props means `__tests__/PublishStatusScreen.test.tsx`
 * can render the real `PublishStatusView` — every loading/error/empty/
 * populated branch, the flag, the retry button — against plain fakes,
 * without needing a working `<MemoryRouter>` at all. `PublishStatusScreen`
 * itself (the real router wiring) is exercised for real by every other
 * screen reachable through `routes.tsx` in the running app — verified
 * directly against the live dev server + API, see this agent's report.
 */
import { useEffect } from "react";
import { useNavigate, useSearchParams, type NavigateFunction, type SetURLSearchParams } from "react-router-dom";
import { PageHead } from "@/shell/PageHead";
import { Toolbar } from "@/shell/Toolbar";
import { Panel, PanelHead } from "@/ui/Panel";
import { Button } from "@/ui/Button";
import { Tag } from "@/ui/Tag";
import { Flag } from "@/ui/Flag";
import { PillSelect } from "@/ui/Field";
import { RowActions } from "@/ui/RowActions";
import { CellMain, Table, TBody, TD, TH, THead, TR } from "@/ui/Table";
import { EmptyState, ErrorState, LoadingState, TableSkeleton } from "@/ui/States";
import { ArrowLeftIcon, ArrowRightIcon, ArrowUpRightIcon, BroadcastIcon, NotePencilIcon } from "@/ui/icons";
import { useMyAds } from "@/data/useAds";
import { usePublishStatusForAd } from "@/data/usePublish";
import { formatDateTime } from "@/lib/format";
import { PUBLISH_CHANNEL_LABEL } from "@/lib/labels";
import { CHANNEL_CAPABILITY, CHANNEL_ICON, PUBLISH_STATUS_CHANNELS } from "./channelCapability";
import { RETRY_GAP_MESSAGE, adReference, adTitle, publishStatusView } from "./helpers";

const CRUMB = "Console · Workspace";

export interface PublishStatusViewProps {
  navigate: NavigateFunction;
  searchParams: URLSearchParams;
  setSearchParams: SetURLSearchParams;
}

export function PublishStatusView({ navigate, searchParams, setSearchParams }: PublishStatusViewProps) {
  const adsQuery = useMyAds();

  const requestedAdId = searchParams.get("adId");
  const ads = adsQuery.data;
  const requestedAdIsMine = ads !== undefined && ads.some((ad) => ad.id === requestedAdId);
  // Trust an explicit ?adId= the instant we see it (avoids a flash of
  // "newest ad" while ads are still loading); once ads have actually
  // loaded, fall back to the newest one the moment the requested id turns
  // out not to be this agent's own.
  const selectedAdId =
    requestedAdId && (ads === undefined || requestedAdIsMine) ? requestedAdId : ads?.[0]?.id;

  useEffect(() => {
    if (!selectedAdId) return;
    if (searchParams.get("adId") === selectedAdId) return;
    const next = new URLSearchParams(searchParams);
    next.set("adId", selectedAdId);
    setSearchParams(next, { replace: true });
  }, [selectedAdId, searchParams, setSearchParams]);

  const publishQuery = usePublishStatusForAd(selectedAdId);

  if (adsQuery.isPending) {
    return (
      <>
        <PageHead crumb={CRUMB} title="Publish status" />
        <LoadingState label="Loading your ads…" />
      </>
    );
  }

  if (adsQuery.isError) {
    return (
      <>
        <PageHead crumb={CRUMB} title="Publish status" />
        <ErrorState error={adsQuery.error} onRetry={() => void adsQuery.refetch()} />
      </>
    );
  }

  const loadedAds = adsQuery.data;
  if (loadedAds.length === 0) {
    return (
      <>
        <PageHead crumb={CRUMB} title="Publish status" />
        <EmptyState
          icon={BroadcastIcon}
          title="No ads to publish yet"
          sub="Publish status tracks channels per ad — create a listing first, then come back here to see how it's going out."
          action={
            <Button variant="dark" icon={NotePencilIcon} onClick={() => navigate("/ads/new")}>
              New listing
            </Button>
          }
        />
      </>
    );
  }

  if (!selectedAdId) {
    // Unreachable in practice — loadedAds.length > 0 guarantees ads[0].id
    // was available when selectedAdId was derived above (same query cache
    // entry). Kept only so selectedAdId narrows to `string` from here down
    // without an unsafe assertion.
    return (
      <>
        <PageHead crumb={CRUMB} title="Publish status" />
        <LoadingState />
      </>
    );
  }

  const selectedAd = loadedAds.find((ad) => ad.id === selectedAdId);
  const channelsSoFar = publishQuery.data?.channels ?? [];
  const hasFailedChannel = PUBLISH_STATUS_CHANNELS.some(
    (channel) => channelsSoFar.find((c) => c.channel === channel)?.status === "FAILED",
  );

  function handleAdChange(event: React.ChangeEvent<HTMLSelectElement>) {
    const next = new URLSearchParams(searchParams);
    next.set("adId", event.target.value);
    setSearchParams(next, { replace: true });
  }

  function renderPublishBody() {
    if (publishQuery.isPending) {
      return (
        <Table>
          <THead>
            <TR>
              <TH>Channel</TH>
              <TH>Automation</TH>
              <TH>Status</TH>
              <TH>External</TH>
              <TH align="right">Last attempt</TH>
              <TH />
            </TR>
          </THead>
          <TableSkeleton rows={4} cols={6} />
        </Table>
      );
    }

    if (publishQuery.isError) {
      return <ErrorState error={publishQuery.error} onRetry={() => void publishQuery.refetch()} />;
    }

    const channels = publishQuery.data.channels;
    const byChannel = new Map(channels.map((c) => [c.channel, c] as const));
    const rows = PUBLISH_STATUS_CHANNELS.map((channel) => byChannel.get(channel));
    const hasAnyAttempt = rows.some((row) => row !== undefined && row.status !== "PENDING");

    if (!hasAnyAttempt) {
      return (
        <EmptyState
          icon={BroadcastIcon}
          title="Not published anywhere yet"
          sub="This ad hasn't been sent to any channel. Publish it from the Listing editor to see status here."
          action={
            <Button variant="dark" icon={NotePencilIcon} onClick={() => navigate(`/ads/${selectedAdId}/edit`)}>
              Open in editor
            </Button>
          }
        />
      );
    }

    return (
      <Table>
        <THead>
          <TR>
            <TH>Channel</TH>
            <TH>Automation</TH>
            <TH>Status</TH>
            <TH>External</TH>
            <TH align="right">Last attempt</TH>
            <TH />
          </TR>
        </THead>
        <TBody>
          {PUBLISH_STATUS_CHANNELS.map((channel) => {
            const row = byChannel.get(channel);
            const capability = CHANNEL_CAPABILITY[channel];
            const Icon = CHANNEL_ICON[channel];
            const status = publishStatusView(row?.status ?? "PENDING");
            const failed = row?.status === "FAILED";

            return (
              <TR key={channel}>
                <TD>
                  <CellMain icon={Icon} title={PUBLISH_CHANNEL_LABEL[channel]} sub={capability.description} />
                </TD>
                <TD>
                  <Tag tone="mute">{capability.tag}</Tag>
                </TD>
                <TD>
                  <Tag tone={status.tone} dot>
                    {status.label}
                  </Tag>
                </TD>
                <TD className="max-w-[220px] truncate font-mono text-tiny">
                  {failed && row?.errorMessage ? (
                    <span className="text-err">{row.errorMessage}</span>
                  ) : row?.externalUrl ? (
                    row.externalUrl.replace(/^https?:\/\//, "")
                  ) : (
                    <span className="text-ink-2">—</span>
                  )}
                </TD>
                <TD align="right" className="font-mono text-tiny">
                  {row?.lastAttemptAt ? formatDateTime(row.lastAttemptAt) : <span className="text-ink-2">—</span>}
                </TD>
                <TD align="right">
                  <RowActions
                    actions={
                      row?.externalUrl
                        ? [
                            {
                              icon: ArrowUpRightIcon,
                              label: `Open on ${PUBLISH_CHANNEL_LABEL[channel]}`,
                              href: row.externalUrl,
                            },
                          ]
                        : []
                    }
                  />
                </TD>
              </TR>
            );
          })}
        </TBody>
      </Table>
    );
  }

  return (
    <>
      <PageHead crumb={CRUMB} title="Publish status" />

      <Toolbar>
        <div className="w-[260px]">
          <PillSelect aria-label="Ad" value={selectedAdId} onChange={handleAdChange}>
            {loadedAds.map((ad) => (
              <option key={ad.id} value={ad.id}>
                {adTitle(ad)}
              </option>
            ))}
          </PillSelect>
        </div>
        <Button variant="default" icon={ArrowLeftIcon} onClick={() => navigate(`/ads/${selectedAdId}/edit`)}>
          Editor
        </Button>
        <div className="flex-1" />
        <Button
          variant="primary"
          icon={ArrowRightIcon}
          disabled
          title={hasFailedChannel ? RETRY_GAP_MESSAGE : "No channel has failed for this ad."}
        >
          Retry failed
        </Button>
      </Toolbar>

      {hasFailedChannel ? <Flag>{RETRY_GAP_MESSAGE}</Flag> : null}

      <Panel>
        <PanelHead
          title={selectedAd ? adTitle(selectedAd) : `Ad ${selectedAdId}`}
          sub={
            <>
              {selectedAd && adReference(selectedAd) ? (
                <span className="font-mono">#{adReference(selectedAd)} · </span>
              ) : null}
              one row per (ad, channel)
            </>
          }
        />
        {renderPublishBody()}
      </Panel>
    </>
  );
}

/** The real route element (routes.tsx's `{ path: "publish", element: <PublishStatusScreen /> }`)
 * — wires the three router primitives PublishStatusView needs and nothing else. See the file
 * header for why this split exists. */
export function PublishStatusScreen() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  return <PublishStatusView navigate={navigate} searchParams={searchParams} setSearchParams={setSearchParams} />;
}
