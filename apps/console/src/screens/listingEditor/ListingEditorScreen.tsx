/**
 * ListingEditorScreen — mockups/f/PLAN.md §3.3 (`a-editor`). Renders for
 * BOTH `/ads/new` and `/ads/:id/edit` (routes.tsx) — create and edit are the
 * same screen, prefilled or not, distinguished only by whether `:id` is
 * present.
 *
 * `ListingEditorScreen` itself (the route wrapper) only wires
 * `useNavigate`/`useParams` and renders `ListingEditorView`, which takes
 * `navigate`/`adId` as props instead — the same split
 * `publishStatus/PublishStatusScreen.tsx` uses and explains in its own file
 * header: `react-router-dom` is hoisted to the workspace root and its hooks
 * crash mid-render under this app's vitest setup, independent of anything
 * this screen does. Threading the two router primitives through as props
 * means the test suite can render the real `ListingEditorView` — every
 * mode/loading/error/validation/save/delete branch — against plain fakes,
 * without a working `<MemoryRouter>` at all.
 *
 * Save/update goes straight through `apiClient.ads.create`/`.update`
 * (`@lacasa/api-client`'s ads resource already backs both — POST /ads,
 * PATCH /ads/:id) via a `useMutation` scoped to this file, the same pattern
 * `leads/CreateLeadModal.tsx` uses for its own create call: `src/data/
 * useAds.ts` intentionally has no `useCreateAd`/`useUpdateAd` hook (per this
 * screen's own build brief), so this mutates through the resource directly
 * rather than adding exports to a shared, concurrently-owned data module.
 *
 * On a successful save this navigates back to `/ads` (My ads) and
 * invalidates `queryKeys.ads.all` — per this screen's own build brief.
 *
 * API validation errors surface as a single inline banner (`role="alert"`)
 * near the Save buttons, the same place `CreateLeadModal.tsx` puts its own
 * mutation error — never a toast (this app has no toast system) and never
 * silently swallowed. Client-side field errors (`adFormFields.ts#
 * validateForm`, a mirror of `adInputSchema`'s own length/type constraints)
 * render inline under each field via `Field`'s own `hint` slot, in red.
 */
import { useEffect, useRef, useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams, type NavigateFunction } from "react-router-dom";
import type { Ad } from "@lacasa/api-client";
import type { ApiError, AdInput } from "@lacasa/domain";
import { apiClient } from "@/lib/apiClient";
import { queryKeys } from "@/data/queryKeys";
import { useAd, useDeleteAd } from "@/data/useAds";
import { useCoworkers } from "@/data/useCoworkers";
import { useInstagramAccounts } from "@/data/useConnectedAccounts";
import { useAuth } from "@/lib/auth";
import { formatDateTime } from "@/lib/format";
import { AD_STAGE_LABEL, AD_STAGE_TONE } from "@/lib/labels";
import { PageHead } from "@/shell/PageHead";
import { Button } from "@/ui/Button";
import { ArrowLeftIcon, CheckIcon, TrashIcon } from "@/ui/icons";
import { ErrorState, LoadingState } from "@/ui/States";
import { Tag } from "@/ui/Tag";
import { ConfirmDeleteDialog } from "./ConfirmDeleteDialog";
import { MediaPanel } from "./MediaPanel";
import { PropertyDetailsPanel } from "./PropertyDetailsPanel";
import { PublishPanel, type PublishChannelState } from "./PublishPanel";
import { VisibilityPanel } from "./VisibilityPanel";
import { usePhotoUpload } from "./usePhotoUpload";
import {
  EMPTY_FORM_STATE,
  adReferenceOf,
  adTitleOf,
  buildAdInput,
  buildFormStateFromAd,
  stageKeyOf,
  updatedAtOf,
  validateForm,
  type AdFormState,
  type FormErrors,
} from "./adFormFields";

const CRUMB = "Console · Workspace";

export interface ListingEditorViewProps {
  navigate: NavigateFunction;
  adId: string | undefined;
}

export function ListingEditorView({ navigate, adId }: ListingEditorViewProps) {
  const isCreate = !adId;

  const adQuery = useAd(adId ?? "");
  const coworkersQuery = useCoworkers();
  const instagramQuery = useInstagramAccounts();
  const { user } = useAuth();
  const deleteAd = useDeleteAd();
  const queryClient = useQueryClient();

  const [form, setForm] = useState<AdFormState>(EMPTY_FORM_STATE);
  const [errors, setErrors] = useState<FormErrors>({});
  const [pendingDelete, setPendingDelete] = useState(false);
  const initializedRef = useRef(isCreate);

  // Edit mode: fill the form exactly once, the moment the real Ad arrives —
  // never again after that, so an in-flight refetch (e.g. after Save) can't
  // stomp on whatever the agent is currently typing.
  useEffect(() => {
    if (initializedRef.current) return;
    if (adQuery.data) {
      setForm(buildFormStateFromAd(adQuery.data));
      initializedRef.current = true;
    }
  }, [adQuery.data]);

  function patchForm(patch: Partial<AdFormState>) {
    setForm((current) => ({ ...current, ...patch }));
  }

  const instagramConnected = (instagramQuery.data?.length ?? 0) > 0;
  const tgChannelCount = user?.tgChatIds?.length ?? 0;
  const [channels, setChannels] = useState<PublishChannelState>({ instagram: false, telegram: false, youtube: false });
  const channelsTouchedRef = useRef(false);
  useEffect(() => {
    if (channelsTouchedRef.current) return;
    setChannels({ instagram: instagramConnected, telegram: tgChannelCount > 0, youtube: false });
  }, [instagramConnected, tgChannelCount]);
  function handleChannelsChange(next: PublishChannelState) {
    channelsTouchedRef.current = true;
    setChannels(next);
  }

  const { uploading, error: uploadError, uploadFiles } = usePhotoUpload();
  async function handleAddFiles(files: FileList) {
    const urls = await uploadFiles(files);
    if (urls.length > 0) patchForm({ photos: [...form.photos, ...urls] });
  }
  function handleRemovePhoto(index: number) {
    patchForm({ photos: form.photos.filter((_, i) => i !== index) });
  }

  const saveMutation = useMutation<Ad, ApiError, AdInput>({
    mutationFn: (input) => (isCreate ? apiClient.ads.create(input) : apiClient.ads.update(adId as string, input)),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.ads.all });
      navigate("/ads");
    },
  });

  // Typed structurally (not `FormEvent`) so both the <form onSubmit> path
  // (Save) and the plain <button onClick> path (Save draft) can call this
  // with their own, differently-shaped synthetic event.
  function handleSubmit(event: { preventDefault(): void }, forceDraft: boolean) {
    event.preventDefault();
    const requireCore = !forceDraft;
    const nextErrors = validateForm(form, { requireCore });
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;
    saveMutation.mutate(buildAdInput(form, { forceDraft }));
  }

  function confirmDelete() {
    if (!adId) return;
    deleteAd.mutate(adId, { onSuccess: () => navigate("/ads") });
  }

  if (!isCreate && adQuery.isLoading) {
    return (
      <>
        <PageHead crumb={CRUMB} title="Listing editor" />
        <LoadingState label="Loading listing…" />
      </>
    );
  }

  if (!isCreate && adQuery.isError) {
    return (
      <>
        <PageHead crumb={CRUMB} title="Listing editor" />
        <ErrorState error={adQuery.error} onRetry={() => void adQuery.refetch()} />
      </>
    );
  }

  const ad = !isCreate ? adQuery.data : undefined;
  const stageKey = ad ? stageKeyOf(ad) : undefined;
  // undefined = "coworkers list still loading" (VisibilityPanel shows
  // "Loading…"), null = "genuinely unassigned" ("Unassigned") — kept
  // distinct from "assigned but not found in the loaded list" (also falls
  // back to null/"Unassigned" once coworkers *have* loaded) rather than
  // conflating "still fetching" with "no such coworker".
  const ownCoworker = !ad?.coworkerId
    ? null
    : coworkersQuery.data === undefined
      ? undefined
      : (coworkersQuery.data.find((c) => c.id === ad.coworkerId) ?? null);

  return (
    <>
      <PageHead crumb={CRUMB} title="Listing editor" />

      <form onSubmit={(event) => handleSubmit(event, false)}>
        <div className="mb-4 flex flex-wrap items-center gap-2">
          <Button type="button" icon={ArrowLeftIcon} onClick={() => navigate("/ads")}>
            My ads
          </Button>
          {ad ? (
            <>
              {stageKey ? (
                <Tag tone={AD_STAGE_TONE[stageKey]} dot={stageKey === "1"}>
                  {AD_STAGE_LABEL[stageKey]}
                </Tag>
              ) : null}
              <span className="font-mono text-tiny text-ink-2">
                {adReferenceOf(ad) ? `#${adReferenceOf(ad)} · ` : ""}
                updated {formatDateTime(updatedAtOf(ad))}
              </span>
            </>
          ) : null}
          <div className="flex-1" />
          {!isCreate ? (
            <Button
              type="button"
              variant="danger"
              icon={TrashIcon}
              onClick={() => setPendingDelete(true)}
              disabled={deleteAd.isPending}
            >
              Delete
            </Button>
          ) : null}
          <Button type="button" onClick={(event) => handleSubmit(event, true)} disabled={saveMutation.isPending}>
            Save draft
          </Button>
          <Button type="submit" variant="primary" icon={CheckIcon} disabled={saveMutation.isPending}>
            {saveMutation.isPending ? "Saving…" : "Save"}
          </Button>
        </div>

        {saveMutation.isError ? (
          <p role="alert" className="mb-3.5 rounded-input bg-err-soft px-3.5 py-2.5 text-caption text-err">
            {saveMutation.error.message}
          </p>
        ) : null}

        <div className="grid grid-cols-1 items-start gap-[26px] lg:grid-cols-[1fr_330px]">
          <div>
            <PropertyDetailsPanel form={form} errors={errors} onChange={patchForm} />
            <MediaPanel
              photos={form.photos}
              uploading={uploading}
              uploadError={uploadError}
              onAddFiles={handleAddFiles}
              onRemove={handleRemovePhoto}
            />
          </div>
          <div>
            <PublishPanel
              channels={channels}
              onChannelsChange={handleChannelsChange}
              instagramStatus={instagramQuery.isLoading ? "Loading…" : instagramConnected ? "Connected" : "Not connected"}
              telegramStatus={tgChannelCount > 0 ? `${tgChannelCount} channel${tgChannelCount === 1 ? "" : "s"} connected` : "Not connected"}
            />
            <VisibilityPanel
              active={form.active}
              onActiveChange={(checked) => patchForm({ active: checked })}
              markAsSold={form.markAsSold}
              onMarkAsSoldChange={(checked) => patchForm({ markAsSold: checked })}
              coworker={ownCoworker}
            />
          </div>
        </div>
      </form>

      {pendingDelete ? (
        <ConfirmDeleteDialog
          adTitle={ad ? adTitleOf(ad) : "This listing"}
          pending={deleteAd.isPending}
          error={deleteAd.isError ? deleteAd.error.message : null}
          onCancel={() => setPendingDelete(false)}
          onConfirm={confirmDelete}
        />
      ) : null}
    </>
  );
}

/** The real route element (routes.tsx's `ads/new` and `ads/:id/edit` both
 * pointing here) — wires the two router primitives ListingEditorView needs
 * and nothing else. See the file header for why this split exists. */
export function ListingEditorScreen() {
  const navigate = useNavigate();
  const { id } = useParams();
  return <ListingEditorView navigate={navigate} adId={id} />;
}
