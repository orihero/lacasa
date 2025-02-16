import { gapi } from "gapi-script";
import MediaUploader from "./cors_upload";

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
      const authInstance = gapi.auth2.getAuthInstance();
      const accessToken = authInstance.currentUser
        .get()
        .getAuthResponse().access_token;

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

  // Upload a video to YouTube
  public static uploadVideo = async (
    file: File,
    metadata: Record<string, any>,
    onProgress: (
      estimatedSecondsRemaining: number,
      percentageComplete: number,
    ) => void,
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
        },
        onError: (error: string) => {
          try {
            const errorResponse = JSON.parse(error);
            console.error("YouTube API Error:", errorResponse.error.message);
            alert(`Error: ${errorResponse.error.message}`);
          } catch (parseError) {
            console.error("Upload failed:", error);
            alert("An error occurred during the upload.");
          }
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
