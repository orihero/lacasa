// OLX.uz orchestrator (docs/07 §3-5): snapshot → LLM map → execute per step.
// Never clicks Publish — the human reviews and publishes themselves.
import { sendToBackground } from "../lib/messaging";
import type { CrosspostJob, MapFieldsResponse, PhotoPayload } from "../lib/types";
import { snapshotCategoryPanel, snapshotStep, structuralHash } from "./dom-snapshot";
import { applyAction, attachPhotos, clickOption, waitForMutation } from "./dom-executor";
import { ReviewBanner } from "../ui/review-banner";
import { clearHighlights, highlightField } from "../ui/highlight";

const CONFIDENCE_THRESHOLD = 0.75;

async function mapFields(step: string, snapshot: ReturnType<typeof snapshotStep>): Promise<MapFieldsResponse> {
  const res = await sendToBackground<MapFieldsResponse>({ type: "MAP_FIELDS", step, snapshot });
  if (!res.ok) throw new Error(res.error);
  return res.data;
}

async function confirm(event: "drafted" | "published" | "failed" | "aborted" | "dom-drift", extra?: { externalUrl?: string; errorMessage?: string }): Promise<void> {
  await sendToBackground({ type: "CONFIRM", event, ...extra });
}

async function selectCategory(banner: ReviewBanner): Promise<void> {
  for (let level = 0; level < 6; level++) {
    const panel = snapshotCategoryPanel(document.body, level);
    if (!panel) return; // picker closed or not present — category done
    banner.setMessage(`Choosing category (step ${level + 1})…`);
    const map = await mapFields(level === 0 ? "category" : `category-${level}`, [panel]);
    if (!map.categoryClick) return;
    const target = document.querySelector(`[data-lacasa-ref="${map.categoryClick.ref}"]`);
    if (!target) throw new Error("Category option disappeared");
    clickOption(target);
    const changed = await waitForMutation(document.body, 5000);
    if (!changed) {
      banner.setMessage("Couldn't confirm the category changed — please continue the category manually, then use the buttons below.");
      return;
    }
  }
}

async function fillDetails(banner: ReviewBanner): Promise<{ applied: number; total: number; review: number }> {
  banner.setMessage("Reading the form…");
  const root = document.querySelector("form") ?? document.body;
  const snapshot = snapshotStep(root);

  // Drift telemetry (docs/07 §6): compare against last run's structural hash.
  const hash = structuralHash(snapshot);
  const { olxDetailsHash } = await chrome.storage.local.get("olxDetailsHash");
  if (olxDetailsHash && olxDetailsHash !== hash) {
    void confirm("dom-drift");
  }
  await chrome.storage.local.set({ olxDetailsHash: hash });

  banner.setMessage("Mapping listing data onto the form…");
  const map = await mapFields("details", snapshot);

  let applied = 0;
  let review = 0;
  for (const action of map.fields) {
    if (action.confidence < CONFIDENCE_THRESHOLD) {
      highlightField(action.ref, `Suggested: ${action.value} — low confidence, please check.`);
      review++;
      continue;
    }
    const result = await applyAction(action);
    if (result.ok) applied++;
    else {
      highlightField(action.ref, `Suggested: ${action.value} — ${result.reason ?? "could not apply"}.`);
      review++;
    }
  }
  for (const u of map.unresolved) {
    highlightField(u.ref, u.reason);
    review++;
  }
  return { applied, total: map.fields.length + map.unresolved.length, review };
}

async function fillPhotos(banner: ReviewBanner, job: CrosspostJob): Promise<boolean> {
  const input = document.querySelector('input[type="file"]') as HTMLInputElement | null;
  if (!input || !job.photoUrls.length) return false;
  banner.setMessage(`Attaching ${job.photoUrls.length} photo(s)…`);
  // Batches of 3 keep messages bounded (docs/07 §5); a DataTransfer replaces
  // input.files wholesale, so accumulate and attach once at the end.
  const photos: PhotoPayload[] = [];
  for (let i = 0; i < job.photoUrls.length; i += 3) {
    const res = await sendToBackground<PhotoPayload[]>({ type: "FETCH_PHOTOS", urls: job.photoUrls.slice(i, i + 3) });
    if (!res.ok) throw new Error(res.error);
    photos.push(...res.data);
  }
  attachPhotos(input, photos);
  return true;
}

function watchForPublishOutcome(banner: ReviewBanner): void {
  // Best-effort: OLX redirects to a success page after the human clicks
  // Publish. Self-report buttons remain the authoritative path.
  const startUrl = location.href;
  const timer = setInterval(() => {
    if (location.href !== startUrl && /success|confirm|adding/i.test(location.href)) {
      clearInterval(timer);
      void confirm("published", { externalUrl: location.href });
      banner.setMessage("Looks published — logged it. You can close this tab.");
      banner.setActions([]);
    }
  }, 1500);
  setTimeout(() => clearInterval(timer), 30 * 60 * 1000);
}

async function run(job: CrosspostJob, banner: ReviewBanner): Promise<void> {
  try {
    await selectCategory(banner);
    // The details form renders after the category is picked.
    await new Promise((r) => setTimeout(r, 800));
    const stats = await fillDetails(banner);
    const hasPhotos = await fillPhotos(banner, job).catch((e) => {
      banner.setMessage(`Photo attach failed: ${e.message}. Please add photos manually.`);
      return false;
    });
    await confirm("drafted");
    banner.setMessage(
      `Autofilled ${stats.applied} of ${stats.total} fields.` +
        (stats.review ? ` ${stats.review} field(s) need your review (highlighted).` : "") +
        (hasPhotos ? " Photos attached." : " Please add photos manually.") +
        "\n\nCheck everything (especially price), then click OLX's own Publish button yourself.",
    );
    banner.setActions([
      { label: "Mark as published", primary: true, onClick: () => void onPublished(banner) },
      { label: "Abort", onClick: () => void onAbort(banner) },
    ]);
    watchForPublishOutcome(banner);
  } catch (e) {
    banner.setMessage(`Autofill stopped: ${(e as Error).message}\nYou can finish the form manually.`);
    banner.setActions([
      { label: "Mark as published", primary: true, onClick: () => void onPublished(banner) },
      { label: "Abort", onClick: () => void onAbort(banner) },
    ]);
  }
}

async function onPublished(banner: ReviewBanner): Promise<void> {
  await confirm("published", { externalUrl: location.href });
  clearHighlights();
  banner.setMessage("Marked as published. You can close this tab.");
  banner.setActions([]);
}

async function onAbort(banner: ReviewBanner): Promise<void> {
  await confirm("aborted");
  clearHighlights();
  banner.remove();
}

async function main(): Promise<void> {
  const res = await sendToBackground<CrosspostJob | null>({ type: "JOB_REQUEST" });
  if (!res.ok || !res.data) return; // tab opened manually — stay dormant
  const job = res.data;
  if (job.channel !== "olx") return;

  const banner = new ReviewBanner("La Casa → OLX");
  banner.setMessage(
    `Ready to autofill this OLX form from "${String((job.ad as any).title ?? job.adId)}".\n` +
      "Nothing is touched until you press Start; you always click Publish yourself.",
  );
  banner.setActions([
    { label: "Start autofill", primary: true, onClick: () => void run(job, banner) },
    { label: "Cancel", onClick: () => void onAbort(banner) },
  ]);
}

void main();
