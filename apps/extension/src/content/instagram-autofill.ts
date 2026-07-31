// Instagram web-composer orchestrator (docs/09 §2, extended to full
// automation): opens the composer, injects the listing photos, and fills an
// LLM-written caption. It never clicks Share — the human reviews the post and
// shares it themselves, then self-reports via the banner.
import { sendToBackground } from "../lib/messaging";
import type { CrosspostJob, MapFieldsResponse, PhotoPayload } from "../lib/types";
import { snapshotStep } from "./dom-snapshot";
import { applyAction, attachPhotos, clickOption } from "./dom-executor";
import { ReviewBanner } from "../ui/review-banner";
import { clearHighlights, highlightField } from "../ui/highlight";

const CREATE_LABELS = ["new post", "create", "создать", "новая публикация", "yangi post", "yaratish"];
const NEXT_LABELS = ["next", "далее", "keyingisi", "keyingi"];

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function waitFor<T>(fn: () => T | null | undefined, timeoutMs = 15000, interval = 400): Promise<T> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const value = fn();
    if (value) return value;
    await sleep(interval);
  }
  throw new Error("Timed out waiting for Instagram's UI");
}

function findByAria(labels: string[]): HTMLElement | null {
  for (const el of Array.from(document.querySelectorAll<HTMLElement>("[aria-label]"))) {
    const label = (el.getAttribute("aria-label") ?? "").toLowerCase().trim();
    if (labels.some((l) => label === l || label.startsWith(l))) {
      // svg icons carry the label; click their interactive ancestor
      return (el.closest('a, [role="button"], [role="link"], button') as HTMLElement) ?? el;
    }
  }
  return null;
}

function findDialogButton(labels: string[]): HTMLElement | null {
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) return null;
  for (const el of Array.from(dialog.querySelectorAll<HTMLElement>('[role="button"], button'))) {
    const text = (el.textContent ?? "").toLowerCase().trim();
    if (labels.includes(text)) return el;
  }
  return null;
}

async function mapFields(step: string, snapshot: ReturnType<typeof snapshotStep>): Promise<MapFieldsResponse> {
  const res = await sendToBackground<MapFieldsResponse>({ type: "MAP_FIELDS", step, snapshot });
  if (!res.ok) throw new Error(res.error);
  return res.data;
}

async function confirm(event: "drafted" | "published" | "failed" | "aborted", extra?: { errorMessage?: string }): Promise<void> {
  await sendToBackground({ type: "CONFIRM", event, ...extra });
}

async function openComposer(banner: ReviewBanner): Promise<void> {
  banner.setMessage("Opening the composer…");
  // Heuristic first; fall back to an LLM pass over the visible controls.
  let createBtn = findByAria(CREATE_LABELS);
  if (!createBtn) {
    const map = await mapFields("composer", snapshotStep(document.body));
    const click = map.fields.find((f) => f.action === "click-radio");
    if (click) {
      await applyAction(click);
    } else {
      throw new Error("Couldn't find Instagram's Create button — click it manually, then press Start again.");
    }
  } else {
    clickOption(createBtn);
  }
  await waitFor(() => document.querySelector('[role="dialog"] input[type="file"]'));
}

async function injectPhotos(banner: ReviewBanner, job: CrosspostJob): Promise<void> {
  banner.setMessage(`Adding ${job.photoUrls.length} photo(s)…`);
  const photos: PhotoPayload[] = [];
  for (let i = 0; i < job.photoUrls.length; i += 3) {
    const res = await sendToBackground<PhotoPayload[]>({ type: "FETCH_PHOTOS", urls: job.photoUrls.slice(i, i + 3) });
    if (!res.ok) throw new Error(res.error);
    photos.push(...res.data);
  }
  const input = document.querySelector('[role="dialog"] input[type="file"]') as HTMLInputElement | null;
  if (!input) throw new Error("Couldn't find the photo input");
  attachPhotos(input, photos);
  // Crop step appears once IG has processed the files.
  await waitFor(() => findDialogButton(NEXT_LABELS), 20000);
}

async function advanceToCaption(): Promise<void> {
  // Crop -> edit -> caption: two Next clicks, tolerating layout variations.
  for (let i = 0; i < 2; i++) {
    const next = await waitFor(() => findDialogButton(NEXT_LABELS), 15000);
    clickOption(next);
    await sleep(1200);
  }
  await waitFor(() => captionEditor(), 15000);
}

function captionEditor(): HTMLElement | null {
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) return null;
  return (
    (dialog.querySelector('div[contenteditable="true"][aria-label]') as HTMLElement) ??
    (dialog.querySelector("textarea[aria-label]") as HTMLElement) ??
    null
  );
}

async function fillCaption(banner: ReviewBanner): Promise<void> {
  banner.setMessage("Writing the caption…");
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) throw new Error("Composer dialog disappeared");
  // "caption" is the once-per-session step that drives the server-side daily
  // cap, so it is always an LLM call even though there is one obvious field.
  const map = await mapFields("caption", snapshotStep(dialog));
  const setValue = map.fields.find((f) => f.action === "set-value");
  if (!setValue) throw new Error("The caption could not be mapped");
  const result = await applyAction(setValue);
  if (!result.ok) {
    highlightField(setValue.ref, "Caption could not be inserted — paste it manually.");
    throw new Error(`Caption insert failed: ${result.reason ?? "unknown"}`);
  }
}

async function run(job: CrosspostJob, banner: ReviewBanner): Promise<void> {
  try {
    await openComposer(banner);
    await injectPhotos(banner, job);
    await advanceToCaption();
    await fillCaption(banner);
    await confirm("drafted");
    banner.setMessage(
      "Photos added and caption written.\n\nReview the post — edit anything you like — then click Instagram's own Share button yourself. Afterwards, press \"Mark as posted\".",
    );
  } catch (e) {
    await confirm("drafted").catch(() => undefined);
    banner.setMessage(
      `Autofill stopped: ${(e as Error).message}\nYou can finish the post manually, then use the buttons below.`,
    );
  }
  banner.setActions([
    { label: "Mark as posted", primary: true, onClick: () => void onPosted(banner) },
    { label: "Abort", onClick: () => void onAbort(banner) },
  ]);
}

async function onPosted(banner: ReviewBanner): Promise<void> {
  await confirm("published");
  clearHighlights();
  banner.setMessage("Marked as posted. You can close this tab.");
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
  if (job.channel !== "instagram") return;

  const banner = new ReviewBanner("La Casa → Instagram");
  banner.setMessage(
    `Ready to draft an Instagram post for "${String((job.ad as any).title ?? job.adId)}".\n` +
      "The extension adds the photos and writes a caption; you review and click Share yourself. Make sure you're logged into the right account.",
  );
  banner.setActions([
    { label: "Start", primary: true, onClick: () => void run(job, banner) },
    { label: "Cancel", onClick: () => void onAbort(banner) },
  ]);
}

void main();
