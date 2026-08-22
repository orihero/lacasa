import { gapi } from "gapi-script";
import MediaUploader from "./cors_upload";
import { apiClient } from "../lib/apiClient";

// YouTube uploads stay client-side (the user's own OAuth token, per
// docs/08-publish-tracking.md — this is NOT part of the Telegram-token
// leak this migration fixes). What was missing is the report-back: the
// server never learned whether an upload happened, so YOUTUBE never showed
// up in the publish-status grid. reportYoutubeStatus() below posts the
// outcome to POST /api/publish/youtube after the resumable upload settles.
// It deliberately never throws — a failed report-back must not mask the
// upload result the user already saw via onComplete/onError's alert().
async function reportYoutubeStatus(
  input:
    | { adId: string; status: "PUBLISHED"; externalId: string }
    | { adId: string; status: "FAILED"; errorMessage?: string },
): Promise<void> {
  try {
    await apiClient.publish.reportYoutubeStatus(input);
  } catch (error) {
    console.error("Failed to report YouTube publish status to the server:", error);
  }
}

export class YTService {
  // Initialize the YouTube API client
  public static init = async (): Promise<string | null> => {
    try {
      await new Promise((resolve, reject) => {
        gapi.load("client:auth2", {
          callback: resolve,
          onerror: () => reject("Google API client failed to load."),
        });
      });

      await gapi.client.init({
        apiKey: import.meta.env.VITE_YT_TOKEN, // Replace with your API Key
        clientId: import.meta.env.VITE_YT_CLIEND_ID, // Replace with your OAuth Client ID
        scope: "https://www.googleapis.com/auth/youtube.upload",
        discoveryDocs: [
          "https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest",
        ],
      });

      const authInstance = gapi.auth2.getAuthInstance();

      if (authInstance.isSignedIn.get()) {
        const accessToken = authInstance.currentUser
          .get()
          .getAuthResponse().access_token;
        return accessToken;
      }

      // If not signed in, prompt the user to sign in
      const user = await authInstance.signIn();
      console.log(user);
      const accessToken = user.getAuthResponse().access_token;
      console.log({ accessToken });
      return accessToken;
    } catch (error) {
      console.error("Error initializing YouTube API:", error);
      return null;
    }
  };

  public static getChannelInfo = async (): Promise<any> => {
    try {
      const response = await gapi.client.youtube.channels.list({
        part: "snippet,contentDetails,statistics", // Specify the details you need
        mine: true, // Get the channel info of the authenticated user
      });

      const channelInfo = response.result.items[0]; // The first item contains channel details
      console.log("Channel Info:", channelInfo);
      return channelInfo;
    } catch (error) {
      console.error("Error fetching channel info:", error);
      throw new Error("Failed to fetch channel details.");
    }
  };

  // Upload a video to YouTube. `adId` is the ad this upload belongs to
  // (draft or real) — required so the report-back in onComplete/onError can
  // tell the server which AdPublication row to upsert.
  public static uploadVideo = async (
    file: File,
    metadata: Record<string, any>,
    onProgress: (
      estimatedSecondsRemaining: number,
      percentageComplete: number,
    ) => void,
    adId: string,
  ): Promise<void> => {
    if (!file) {
      alert("Please select a file to upload");
      return;
    }

    const uploadStartTime = Date.now();

    try {
      const authInstance = gapi.auth2.getAuthInstance();
      const accessToken = authInstance.currentUser
        .get()
        .getAuthResponse().access_token;

      const uploader = new MediaUploader({
        file,
        token: accessToken,
        baseUrl: "https://www.googleapis.com/upload/youtube/v3/videos",
        metadata,
        params: {
          part: Object.keys(metadata).join(","),
        },
        onComplete: (data: string) => {
          const uploadResponse = JSON.parse(data);
          console.log("Video uploaded successfully:", uploadResponse);
          const externalId = uploadResponse?.id;
          if (externalId) {
            void reportYoutubeStatus({ adId, status: "PUBLISHED", externalId });
          } else {
            console.error("YouTube upload response had no video id; cannot report status", uploadResponse);
            void reportYoutubeStatus({
              adId,
              status: "FAILED",
              errorMessage: "Upload succeeded but the response had no video id",
            });
          }
        },
        onError: (error: string) => {
          let errorMessage = "An error occurred during the upload.";
          try {
            const errorResponse = JSON.parse(error);
            errorMessage = errorResponse?.error?.message ?? errorMessage;
            console.error("YouTube API Error:", errorMessage);
            alert(`Error: ${errorMessage}`);
          } catch {
            console.error("Upload failed:", error);
            alert("An error occurred during the upload.");
          }
          void reportYoutubeStatus({ adId, status: "FAILED", errorMessage });
        },
        onProgress: (data: ProgressEvent) => {
          const currentTime = Date.now();
          const bytesUploaded = data.loaded;
          const totalBytes = data.total;

          const bytesPerSecond =
            bytesUploaded / ((currentTime - uploadStartTime) / 1000);
          const estimatedSecondsRemaining =
            (totalBytes - bytesUploaded) / bytesPerSecond;
          const percentageComplete = (bytesUploaded * 100) / totalBytes;

          console.log("Upload progress:", {
            estimatedSecondsRemaining,
            percentageComplete,
          });

          onProgress(estimatedSecondsRemaining, percentageComplete);
        },
      });

      uploader.upload();
    } catch (error) {
      console.error("Error during video upload:", error);
    }
  };

  public static signOut = async () => {
    const authInstance = gapi.auth2.getAuthInstance();
    authInstance.signOut();
    console.log("Signed out successfully");
  };
}
