// YouTube uploads stay client-side OAuth (not a Telegram-token leak), but
// the server never learned the outcome — so YOUTUBE never showed up in the
// publish-status grid. This proves uploadVideo()'s onComplete/onError now
// report back to POST /api/publish/youtube via @lacasa/api-client, and that
// a failed report-back never throws (it must not mask the upload result the
// user already saw via alert()).
import { beforeEach, describe, expect, it, vi } from "vitest";

const mediaUploaderConfigs: any[] = [];

vi.mock("./cors_upload", () => ({
  default: class MockMediaUploader {
    constructor(config: any) {
      mediaUploaderConfigs.push(config);
    }
    upload() {}
  },
}));

vi.mock("gapi-script", () => ({
  gapi: {
    auth2: {
      getAuthInstance: () => ({
        currentUser: {
          get: () => ({ getAuthResponse: () => ({ access_token: "tok" }) }),
        },
      }),
    },
  },
}));

vi.mock("../lib/apiClient", () => ({
  apiClient: { publish: { reportYoutubeStatus: vi.fn() } },
}));

import { apiClient } from "../lib/apiClient";
import { YTService } from "./yt";

describe("YTService.uploadVideo — report-back to POST /api/publish/youtube", () => {
  beforeEach(() => {
    mediaUploaderConfigs.length = 0;
    vi.mocked(apiClient.publish.reportYoutubeStatus).mockReset();
    vi.mocked(apiClient.publish.reportYoutubeStatus).mockResolvedValue({} as any);
  });

  it("reports PUBLISHED with the video id once the upload completes", async () => {
    const file = new File(["x"], "video.mp4");
    await YTService.uploadVideo(file, {}, () => {}, "ad-1");

    expect(mediaUploaderConfigs).toHaveLength(1);
    mediaUploaderConfigs[0].onComplete(JSON.stringify({ id: "abc123XYZ_-" }));
    await Promise.resolve();

    expect(apiClient.publish.reportYoutubeStatus).toHaveBeenCalledWith({
      adId: "ad-1",
      status: "PUBLISHED",
      externalId: "abc123XYZ_-",
    });
  });

  it("reports FAILED with the parsed error message when the upload errors", async () => {
    const file = new File(["x"], "video.mp4");
    await YTService.uploadVideo(file, {}, () => {}, "ad-1");

    mediaUploaderConfigs[0].onError(JSON.stringify({ error: { message: "quota exceeded" } }));
    await Promise.resolve();

    expect(apiClient.publish.reportYoutubeStatus).toHaveBeenCalledWith({
      adId: "ad-1",
      status: "FAILED",
      errorMessage: "quota exceeded",
    });
  });

  it("reports FAILED when the upload response has no video id, rather than silently reporting nothing", async () => {
    const file = new File(["x"], "video.mp4");
    await YTService.uploadVideo(file, {}, () => {}, "ad-1");

    mediaUploaderConfigs[0].onComplete(JSON.stringify({}));
    await Promise.resolve();

    expect(apiClient.publish.reportYoutubeStatus).toHaveBeenCalledWith(
      expect.objectContaining({ adId: "ad-1", status: "FAILED" }),
    );
  });

  it("never throws when the report-back call itself fails, so it can't mask the upload result the user already saw", async () => {
    vi.mocked(apiClient.publish.reportYoutubeStatus).mockRejectedValueOnce(new Error("network down"));
    const file = new File(["x"], "video.mp4");
    await YTService.uploadVideo(file, {}, () => {}, "ad-1");

    expect(() => mediaUploaderConfigs[0].onComplete(JSON.stringify({ id: "abc123XYZ_-" }))).not.toThrow();
    // Flush the fire-and-forget promise chain; a leaked rejection here would
    // fail the test via vitest's unhandled-rejection detection.
    await Promise.resolve();
    await Promise.resolve();
  });
});
