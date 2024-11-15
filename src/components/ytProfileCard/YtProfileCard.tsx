import React, { useEffect, useState } from "react";
import { gapi } from "gapi-script";
import MediaUploader from "../../services/cors_upload";
import "./ytProfileCard.scss";

const YtProfileCard = () => {
  const [file, setFile] = useState(null);
  const [uploadStatus, setUploadStatus] = useState("");
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  // OAuth2 Authentication setup
  useEffect(() => {
    gapi.load("client:auth2", () => {
      gapi.client
        .init({
          apiKey: "AIzaSyDlNUD2Zvj8oqCdrJziE71FARwsJIz9Y6U", // Replace with your API key
          clientId:
            "557730361894-p94utq9jhi5lqrc27dc8fl3j1om1usu1.apps.googleusercontent.com", // Replace with your OAuth Client ID
          scope: "https://www.googleapis.com/auth/youtube.upload",
          discoveryDocs: [
            "https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest",
          ],
        })
        .then((res) => {
          console.log(res);
          // Check if user is already authenticated
          if (gapi.auth2.getAuthInstance().isSignedIn.get()) {
            setIsAuthenticated(true);
          }
        });
    });
  }, []);

  // Function to handle file selection
  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  // Function to start OAuth2 sign-in
  const handleSignIn = () => {
    gapi.auth2
      .getAuthInstance()
      .signIn()
      .then(() => {
        setIsAuthenticated(true);
      });
  };

  // Function to handle video upload to YouTube
  const uploadVideoToYouTube = async () => {
    if (!file) {
      alert("Please select a file to upload");
      return;
    }
    if (!isAuthenticated) {
      alert("You need to sign in first!");
      return;
    }

    setUploadStatus("Uploading...");

    // Prepare video metadata
    const metadata = {
      snippet: {
        title: "Video Title", // Set the video title
        description: "Video Description", // Set the video description
        tags: ["tag1", "tag2", "tag3"], // Set tags
        categoryId: "22", // Category ID (22 for People & Blogs, you can use other categories too)
      },
      status: {
        privacyStatus: "private", // Can be 'public', 'private', or 'unlisted'
      },
    };

    // YouTube API request to upload the video
    // const uploadUrl = 'https://www.googleapis.com/upload/youtube/v3/videos?uploadType=multipart&part=snippet,status';

    //  // Create the FormData object for multipart upload
    //  const formData = new FormData();
    //  formData.append('metadata', new Blob([JSON.stringify(metadata)], { type: 'application/json' }));
    //  formData.append('file', file);  // Add the video file

    try {
      const uploader = new MediaUploader({
        file,
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
          var message = data;
          // Assuming the error is raised by the YouTube API, data will be
          // a JSON string with error.message set. That may not be the
          // only time onError will be raised, though.
          try {
            var errorResponse = JSON.parse(data);
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
            bytesUploaded / ((currentTime - this.uploadStartTime) / 1000);
          var estimatedSecondsRemaining =
            (totalBytes - bytesUploaded) / bytesPerSecond;
          var percentageComplete = (bytesUploaded * 100) / totalBytes;
          console.log("====================================");
          console.log({ estimatedSecondsRemaining, percentageComplete });
          console.log("====================================");
        },
      });

      uploader.upload();

      setUploadStatus("Upload Successful!");
      // console.log("Video uploaded:", response);
    } catch (error) {
      console.error("Upload error:", error);
      setUploadStatus("Upload failed");
    }
  };

  return (
    <div className="google-sign-content">
      {/* <h2>Upload a Video to YouTube</h2> */}
      {!isAuthenticated ? (
        <button
          type="button"
          className="sign-google-btn"
          onClick={handleSignIn}
        >
          <img
            src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png"
            alt=""
          />
          Sign In with Google
        </button>
      ) : (
        <div>
          <input type="file" onChange={handleFileChange} />
          <button onClick={uploadVideoToYouTube}>Upload Video</button>
        </div>
      )}
      <p>Status: {uploadStatus}</p>
    </div>
  );
};

export default YtProfileCard;
