// Background service worker: job store, tab lifecycle, API relay, photo
// fetcher. Jobs live in chrome.storage.session keyed by tab id — MV3 workers
// are killed and respawned constantly, so no in-memory state.
import type { BgRequest, BgResponse } from "../lib/messaging";
import type { Channel, CrosspostJob, PhotoPayload } from "../lib/types";

const START_URLS: Record<Channel, string> = {
  olx: "https://www.olx.uz/d/add/",
  instagram: "https://www.instagram.com/",
};

const COOLDOWN_MS = 3 * 60 * 1000; // between completed cross-posts (docs/07 §7)

const jobKey = (tabId: number) => `job:${tabId}`;

async function getJob(tabId: number): Promise<CrosspostJob | null> {
  const stored = await chrome.storage.session.get(jobKey(tabId));
  return (stored[jobKey(tabId)] as CrosspostJob | undefined) ?? null;
}

async function anyActiveJob(): Promise<boolean> {
  const all = await chrome.storage.session.get(null);
  return Object.keys(all).some((k) => k.startsWith("job:"));
}

async function startCrosspost(job: Omit<CrosspostJob, "createdAt">): Promise<void> {
  if (await anyActiveJob()) {
    throw new Error("Another cross-post is already in progress — finish or close it first.");
  }
  const { lastCompletedAt } = await chrome.storage.local.get("lastCompletedAt");
  if (typeof lastCompletedAt === "number" && Date.now() - lastCompletedAt < COOLDOWN_MS) {
    const waitMin = Math.ceil((COOLDOWN_MS - (Date.now() - lastCompletedAt)) / 60000);
    throw new Error(`Please wait ~${waitMin} min between cross-posts.`);
  }
  const tab = await chrome.tabs.create({ url: START_URLS[job.channel] });
  if (tab.id == null) throw new Error("Could not open a tab");
  await chrome.storage.session.set({ [jobKey(tab.id)]: { ...job, createdAt: Date.now() } });
}

async function apiPost(job: CrosspostJob, path: string, body: unknown): Promise<unknown> {
  const res = await fetch(`${job.apiBase}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${job.token}`,
    },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error((data as any)?.error?.message ?? `API error (${res.status})`);
  }
  return data;
}

function toBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

async function fetchPhotos(urls: string[]): Promise<PhotoPayload[]> {
  const out: PhotoPayload[] = [];
  for (const url of urls) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`Failed to fetch photo (${res.status}): ${url}`);
    const buffer = await res.arrayBuffer();
    out.push({
      b64: toBase64(buffer),
      mime: res.headers.get("content-type") ?? "image/jpeg",
      filename: decodeURIComponent(url.split("/").pop()?.split("?")[0] ?? "photo.jpg"),
    });
  }
  return out;
}

async function handle(msg: BgRequest, sender: chrome.runtime.MessageSender): Promise<unknown> {
  switch (msg.type) {
    case "CROSSPOST_REQUEST": {
      await startCrosspost(msg.job);
      return { started: true };
    }
    case "JOB_REQUEST": {
      const tabId = sender.tab?.id;
      if (tabId == null) return null;
      return await getJob(tabId);
    }
    case "MAP_FIELDS": {
      const tabId = sender.tab?.id;
      const job = tabId != null ? await getJob(tabId) : null;
      if (!job) throw new Error("No active cross-post job for this tab");
      return await apiPost(job, `/publish/${job.channel}/map-fields`, {
        adId: job.adId,
        ad: job.ad,
        step: msg.step,
        snapshot: msg.snapshot,
      });
    }
    case "CONFIRM": {
      const tabId = sender.tab?.id;
      const job = tabId != null ? await getJob(tabId) : null;
      if (!job) throw new Error("No active cross-post job for this tab");
      const data = await apiPost(job, `/publish/${job.channel}/confirm`, {
        adId: job.adId,
        event: msg.event,
        externalId: msg.externalId,
        externalUrl: msg.externalUrl,
        errorMessage: msg.errorMessage,
      });
      if (msg.event === "published" || msg.event === "aborted" || msg.event === "failed") {
        await chrome.storage.local.set({ lastCompletedAt: Date.now() });
        if (tabId != null) await chrome.storage.session.remove(jobKey(tabId));
      }
      return data;
    }
    case "FETCH_PHOTOS": {
      return await fetchPhotos(msg.urls);
    }
    case "JOB_DONE": {
      const tabId = sender.tab?.id;
      if (tabId != null) await chrome.storage.session.remove(jobKey(tabId));
      return { ok: true };
    }
  }
}

chrome.runtime.onMessage.addListener((msg: BgRequest, sender, sendResponse) => {
  handle(msg, sender)
    .then((data) => sendResponse({ ok: true, data } satisfies BgResponse))
    .catch((e: Error) => sendResponse({ ok: false, error: e.message } satisfies BgResponse));
  return true; // keep the channel open for the async response
});

chrome.tabs.onRemoved.addListener((tabId) => {
  void chrome.storage.session.remove(jobKey(tabId));
});
