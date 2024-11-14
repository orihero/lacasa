import { useState, useEffect } from "react";
import axios from "axios";
import "./ytProfileCard.scss";
function YouTubeAccountInfo({ accessToken }) {
  //   const [channelInfo, setChannelInfo] = useState(null);

  //   useEffect(() => {
  //     const fetchAccountInfo = async () => {
  //       try {
  //         const response = await axios.get(
  //           "https://www.googleapis.com/youtube/v3/channels",
  //           {
  //             headers: {
  //               Authorization: `Bearer ${accessToken}`,
  //             },
  //             params: {
  //               part: "snippet,contentDetails,statistics",
  //               mine: true, // This specifies to get the authenticated user's channel
  //             },
  //           },
  //         );

  //         setChannelInfo(response.data.items[0]); // Store the first item (your channel info)
  //       } catch (error) {
  //         console.error("Error fetching YouTube channel info:", error);
  //       }
  //     };

  //     if (accessToken) {
  //       fetchAccountInfo();
  //     }
  //   }, [accessToken]);

  return (
    <div className="profile-header">
      <div className="profile-main">
        <div className="profile-avatar">
          <span className="avatar-text">AD</span>
        </div>

        <div className="profile-info">
          <h1 className="profile-name">Diyor Abjalilov</h1>
          <div className="profile-username">@abjalilovdiyor</div>
          <div className="profile-stats">
            <span>101 подписчик</span>
            <span className="dot">•</span>
            <span>20 видео</span>
          </div>

          {/* <div className="profile-description">
            <div className="profile-links">
              <a href="https://t.me/abjalilov_dev" className="telegram-link">
                t.me/abjalilov_dev
              </a>
              <span>и ещё 1 ссылка</span>
            </div>
          </div> */}
        </div>
      </div>

      {/* <div className="profile-actions">
        <button type="button" className="action-button">
          Настроить вид канала
        </button>
        <button type="button" className="action-button">
          Управление видео
        </button>
      </div> */}
    </div>
  );
}

export default YouTubeAccountInfo;
