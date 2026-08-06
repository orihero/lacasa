/**
 * src/screens/myAds/MyAdsScreen — PLAN.md §3.2 (`a-listings`), the console's
 * own ad inventory.
 *
 * Column set is the build brief's own simplification of the prototype's ten
 * raw columns (Listing/Ref/Deal/Price/Rooms/Area/Status/Channels/Author/…):
 * "listing (thumb + title + district/rooms/area), price, stage tag,
 * channels, author avatar, row actions" — district/rooms/area fold into the
 * listing cell's subtitle (deriveMyAds#buildListingSubtitle) instead of
 * three more columns, and the prototype's Ref/Deal columns are dropped
 * entirely rather than guessed at.
 *
 * Stage counts for the segmented filter come from the *fetched* ads list
 * (deriveMyAds#deriveStageCounts), not a second call to the dedicated
 * GET /my/ads/stage-counts endpoint (`useAdStageCounts`) — the brief asks
 * for "LIVE counts derived from the fetched ads" specifically so the
 * segmented control's numbers can never drift from the rows actually on
 * screen underneath it.
 *
 * Stage filtering is client-side (AdFilters has no `stage` param — only
 * `sort` is a real server-side query param), so switching All/Active/Sold/
 * Draft never refetches; switching the sort control does.
 *
 * Accent discipline (PLAN.md §1's table for this screen): the primary "Add
 * new post" CTA and the selected-row tint are the one accent thing — and
 * that CTA is the shell Topbar's own, always-visible one (AppShell.tsx), not
 * a second copy in this screen's content. mockups/f/f-console.src.html's own
 * a-listings section has no `btn--p` at all in its `.tools` row, relying
 * solely on the topbar's; this screen's own Toolbar/EmptyState "Add new
 * post" buttons are `variant="dark"` for the same reason — a second lime
 * button doing the identical thing, visible at the same time as the
 * topbar's, is exactly the "reaching for the accent a second time" defect
 * PLAN.md §1 calls out, not a stylistic nuance.
 */
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import type { Ad, AdSort, AuthUser, Coworker } from "@lacasa/api-client";
import { useDeleteAd, useMyAds } from "@/data/useAds";
import { usePublishStatusForAds } from "@/data/usePublish";
import { useCoworkers } from "@/data/useCoworkers";
import { useAuth } from "@/lib/auth";
import { formatAdPrice } from "@/lib/format";
import { AD_STAGE_LABEL, AD_STAGE_TONE } from "@/lib/labels";
import { PageHead } from "@/shell/PageHead";
import { Toolbar } from "@/shell/Toolbar";
import { Button } from "@/ui/Button";
import { BroadcastIcon, BuildingsIcon, FunnelIcon, NotePencilIcon, PlusIcon, TrashIcon } from "@/ui/icons";
import { Panel } from "@/ui/Panel";
import { Seg } from "@/ui/Seg";
import { EmptyState, ErrorState, TableSkeleton } from "@/ui/States";
import { CellMain, Table, TBody, TD, TH, THead, Thumb, TR } from "@/ui/Table";
import { Tag } from "@/ui/Tag";
import { Avatar } from "@/ui/Avatar";
import { RowActions, type RowAction } from "@/ui/RowActions";
import { ConfirmDeleteDialog } from "./ConfirmDeleteDialog";
import { SortSelect } from "./SortSelect";
import {
  buildListingSubtitle,
  buildSegOptions,
  deriveChannelBadges,
  deriveStageCounts,
  filterAdsByStage,
  resolveAdAuthor,
  stageKey,
  titleOf,
  type StageFilter,
} from "./deriveMyAds";

const COLUMN_COUNT = 6;

export function MyAdsScreen() {
  const navigate = useNavigate();
  const { user } = useAuth();

  const [stageFilter, setStageFilter] = useState<StageFilter>("all");
  const [sort, setSort] = useState<AdSort>("newest");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [pendingDelete, setPendingDelete] = useState<Ad | null>(null);

  const adsQuery = useMyAds({ sort });
  const ads = adsQuery.data;

  const adIds = useMemo(() => ads?.map((ad) => ad.id) ?? [], [ads]);
  const publishQuery = usePublishStatusForAds(adIds);
  const coworkersQuery = useCoworkers();
  const deleteAd = useDeleteAd();

  function goToEditor(ad: Ad) {
    navigate(`/ads/${ad.id}/edit`);
  }
  function goToPublishStatus(ad: Ad) {
    navigate(`/publish?adId=${ad.id}`);
  }
  function goToNewAd() {
    navigate("/ads/new");
  }

  function confirmDelete() {
    if (!pendingDelete) return;
    const id = pendingDelete.id;
    deleteAd.mutate(id, {
      onSuccess: () => {
        setPendingDelete(null);
        setSelectedId((current) => (current === id ? null : current));
      },
    });
  }

  return (
    <>
      <PageHead crumb="Console · Workspace" title="My ads" />

      {adsQuery.isLoading ? (
        <Panel>
          <Table>
            <THead>
              <tr>
                <TH>Listing</TH>
                <TH align="right">Price</TH>
                <TH>Status</TH>
                <TH>Channels</TH>
                <TH>Author</TH>
                <TH />
              </tr>
            </THead>
            <TableSkeleton rows={6} cols={COLUMN_COUNT} />
          </Table>
        </Panel>
      ) : adsQuery.isError ? (
        <ErrorState error={adsQuery.error} onRetry={() => void adsQuery.refetch()} />
      ) : (
        <MyAdsLoaded
          ads={ads ?? []}
          stageFilter={stageFilter}
          onStageFilterChange={setStageFilter}
          sort={sort}
          onSortChange={setSort}
          // Falls back to the first (newest, per the "newest" sort default)
          // ad once `selectedId` hasn't been explicitly set yet — mirrors
          // f-console.src.html's own a-listings section, which hardcodes
          // `is-sel` on ad1001, its first row (PLAN.md §1/§3.2: "ad1001 …
          // (pre-selected, accent-tinted row …)"). An explicit user click
          // (including re-selecting nothing after a delete, confirmDelete
          // above) still wins once selectedId is non-null.
          selectedId={selectedId ?? ads?.[0]?.id ?? null}
          onSelectRow={setSelectedId}
          onAddNew={goToNewAd}
          onEdit={goToEditor}
          onPublishStatus={goToPublishStatus}
          onRequestDelete={setPendingDelete}
          channelsByAdId={publishQuery.data}
          coworkers={coworkersQuery.data ?? []}
          currentUser={user}
        />
      )}

      {pendingDelete ? (
        <ConfirmDeleteDialog
          adTitle={titleOf(pendingDelete)}
          pending={deleteAd.isPending}
          onCancel={() => setPendingDelete(null)}
          onConfirm={confirmDelete}
        />
      ) : null}
    </>
  );
}

/**
 * Split out of MyAdsScreen so the loading/error branches above stay free of
 * the (only-meaningful-once-loaded) stage-count/filter machinery — this
 * component only ever mounts once `adsQuery` has succeeded.
 */
function MyAdsLoaded({
  ads,
  stageFilter,
  onStageFilterChange,
  sort,
  onSortChange,
  selectedId,
  onSelectRow,
  onAddNew,
  onEdit,
  onPublishStatus,
  onRequestDelete,
  channelsByAdId,
  coworkers,
  currentUser,
}: {
  ads: Ad[];
  stageFilter: StageFilter;
  onStageFilterChange: (filter: StageFilter) => void;
  sort: AdSort;
  onSortChange: (sort: AdSort) => void;
  selectedId: string | null;
  onSelectRow: (id: string) => void;
  onAddNew: () => void;
  onEdit: (ad: Ad) => void;
  onPublishStatus: (ad: Ad) => void;
  onRequestDelete: (ad: Ad) => void;
  channelsByAdId: Record<string, Array<{ channel: string; status: string }>> | undefined;
  coworkers: readonly Coworker[];
  currentUser: AuthUser | null;
}) {
  const counts = deriveStageCounts(ads);
  const segOptions = buildSegOptions(counts);
  const visibleAds = filterAdsByStage(ads, stageFilter);

  if (ads.length === 0) {
    return (
      <Panel>
        <EmptyState
          icon={BuildingsIcon}
          title="No ads yet"
          sub="Create your first listing to see it here."
          action={
            // `dark`, not `primary`: the shell Topbar (AppShell.tsx) already
            // renders its own always-visible "Add new post" CTA in the
            // accent color, on every screen including this one — a second
            // lime button here doing the identical thing would be exactly
            // the accent-discipline violation PLAN.md §1 warns against
            // (mockups/f/f-console.src.html's own a-listings screen has no
            // `btn--p` in its content at all, relying solely on the topbar's).
            <Button variant="dark" icon={PlusIcon} onClick={onAddNew}>
              Add new post
            </Button>
          }
        />
      </Panel>
    );
  }

  return (
    <>
      <Toolbar>
        <Seg options={segOptions} value={stageFilter} onChange={onStageFilterChange} />
        <SortSelect value={sort} onChange={onSortChange} />
        <div className="flex-1" />
        {/* `dark`, not `primary` — same reasoning as the EmptyState action
            above: the Topbar's own CTA already owns the accent for "Add new
            post" on every screen, this one included. */}
        <Button variant="dark" icon={PlusIcon} onClick={onAddNew}>
          Add new post
        </Button>
      </Toolbar>
      <Panel>
        {visibleAds.length === 0 ? (
          <EmptyState icon={FunnelIcon} title="No ads match this filter" sub="Try a different stage." />
        ) : (
          <Table>
            <THead>
              <tr>
                <TH>Listing</TH>
                <TH align="right">Price</TH>
                <TH>Status</TH>
                <TH>Channels</TH>
                <TH>Author</TH>
                <TH />
              </tr>
            </THead>
            <TBody>
              {visibleAds.map((ad) => {
                const stage = stageKey(ad.stage);
                const channels = channelsByAdId?.[ad.id];
                const author = resolveAdAuthor(ad, coworkers, currentUser);
                const actions: RowAction[] = [
                  { icon: NotePencilIcon, label: `Edit ${titleOf(ad)}`, onClick: () => onEdit(ad) },
                  {
                    icon: BroadcastIcon,
                    label: `View publish status for ${titleOf(ad)}`,
                    onClick: () => onPublishStatus(ad),
                  },
                  {
                    icon: TrashIcon,
                    label: `Delete ${titleOf(ad)}`,
                    tone: "danger",
                    onClick: () => onRequestDelete(ad),
                  },
                ];

                return (
                  <TR key={ad.id} selected={selectedId === ad.id} onClick={() => onSelectRow(ad.id)}>
                    <TD>
                      <CellMain
                        thumb={<Thumb src={ad.photos[0]} alt={titleOf(ad)} />}
                        title={titleOf(ad)}
                        sub={buildListingSubtitle(ad)}
                      />
                    </TD>
                    <TD align="right">
                      {/* `Ad`'s explicit members (id/agentId/coworkerId/photos/
                          media/lat/lng/tour3dLink) plus its index signature
                          don't structurally satisfy formatAdPrice's
                          Pick<Ad, 'price'|'priceType'|'category'> parameter
                          as a whole `Ad` value — TS won't treat the index
                          signature as covering those three names for that
                          check — so they're picked out into a fresh object
                          literal that does match the shape. */}
                      {formatAdPrice({ price: ad.price, priceType: ad.priceType, category: ad.category })}
                    </TD>
                    <TD>
                      {stage ? (
                        <Tag tone={AD_STAGE_TONE[stage]} dot={stage === "1"}>
                          {AD_STAGE_LABEL[stage]}
                        </Tag>
                      ) : (
                        <Tag tone="mute">—</Tag>
                      )}
                    </TD>
                    <TD>
                      {/* Still loading the batched publish-status call —
                          render nothing rather than guess (build brief). */}
                      {channelsByAdId === undefined ? null : channels === undefined || channels.length === 0 ? (
                        <Tag tone="mute">—</Tag>
                      ) : (
                        <div className="flex flex-wrap gap-1">
                          {deriveChannelBadges(channels).map((badge) => (
                            <Tag key={badge.key} tone={badge.tone}>
                              {badge.label}
                            </Tag>
                          ))}
                        </div>
                      )}
                    </TD>
                    <TD>{author ? <Avatar src={author.avatar} name={author.name} /> : null}</TD>
                    <TD align="right">
                      {/* Row actions must not also trigger the row's own
                          onClick (row selection) when a button inside is
                          pressed. */}
                      <div onClick={(event) => event.stopPropagation()}>
                        <RowActions actions={actions} />
                      </div>
                    </TD>
                  </TR>
                );
              })}
            </TBody>
          </Table>
        )}
      </Panel>
    </>
  );
}
