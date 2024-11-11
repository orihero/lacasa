import { gapi } from "gapi-script";
import MediaUploader from "./cors_upload";

export class YTService {
  public static init = async () => {
    gapi.load("client:auth2", () => {
      gapi.client
        .init({
          //@ts-ignore
          apiKey: import.meta.env.VITE_YT_TOKEN, // Replace with your API key
          //@ts-ignore
          clientId: import.meta.env.VITE_YT_CLIEND_ID, // Replace with your OAuth Client ID
          scope: "https://www.googleapis.com/auth/youtube.upload",
          discoveryDocs: [
            "https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest",
          ],
        })
        .then(() => {
          // Check if user is already authenticated
          //@ts-ignore
          if (gapi.auth2.getAuthInstance().isSignedIn.get()) {
            //@ts-ignore
            return gapi.auth2
              .getAuthInstance()
              .currentUser.get()
              .getAuthResponse().access_token;
          }
        });
    });
    try {
      //@ts-ignore
      await gapi.auth2.getAuthInstance().signIn();
      //@ts-ignore
      return gapi.auth2.getAuthInstance().currentUser.get().getAuthResponse()
        .access_token;
    } catch (error) {
      throw new Error("Error loding youtube", error);
    }
  };
  public static uploadVideo = async (file, metadata) => {
    if (!file) {
      alert("Please select a file to upload");
      return;
    }
    const uploadStartTime = Date.now();
    try {
      const uploader = new MediaUploader({
        file,
        //@ts-ignore
        token: gapi.auth2.getAuthInstance().currentUser.get().getAuthResponse()
          .access_token,
        baseUrl: "https://www.googleapis.com/upload/youtube/v3/videos",
        metadata,
        params: {
          part: Object.keys(metadata).join(","),
        },
        onComplete: (data) => {
          var uploadResponse = JSON.parse(data);
          console.log("====================================");
          console.log({ data });
          console.log("====================================");
        },
        onError: (error) => {
          var message = error;
          // Assuming the error is raised by the YouTube API, data will be
          // a JSON string with error.message set. That may not be the
          // only time onError will be raised, though.
          try {
            var errorResponse = JSON.parse(error);
            message = errorResponse.error.message;
          } finally {
            alert(message);
          }
        },
        onProgress: (data) => {
          var currentTime = Date.now();
          var bytesUploaded = data.loaded;
          var totalBytes = data.total;
          // The times are in millis, so we need to divide by 1000 to get seconds.
          var bytesPerSecond =
            bytesUploaded / ((currentTime - uploadStartTime) / 1000);
          var estimatedSecondsRemaining =
            (totalBytes - bytesUploaded) / bytesPerSecond;
          var percentageComplete = (bytesUploaded * 100) / totalBytes;

          console.log("====================================");
          console.log({ estimatedSecondsRemaining, percentageComplete });
          console.log("====================================");
          onProgress(estimatedSecondsRemaining, percentageComplete);
        },
      });

      uploader.upload();
    } catch (error) {
      console.error("Upload error:", error);
    }
  };
}
