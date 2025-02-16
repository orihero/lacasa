import React from "react";
import "./ytVideoCard.scss";
const YtVideoCard = ({ isVideo, hashtags, title, bannerImg, isShort }) => {
  if (isShort) {
    return (
      <div className="social-post">
        <div className="image-container">
          {isVideo ? (
            <video controls src={bannerImg} className="post-image" />
          ) : (
            <img
              src={
                bannerImg ??
                "https://img.freepik.com/free-photo/vertical-shot-river-surrounded-by-mountains-meadows-scotland_181624-27881.jpg"
              }
              alt="A person speaking at a podium"
              className="post-image"
            />
          )}
        </div>
        <div className="post-content">
          <div className="post-header">
            <h2 className="post-title">
              {title ?? ""}
              <p className="post-title-hashtags">{hashtags ?? ""}</p>
            </h2>

            <button type="button" disabled className="more-options">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="12" r="1" />
                <circle cx="12" cy="5" r="1" />
                <circle cx="12" cy="19" r="1" />
              </svg>
            </button>
          </div>
          <div className="view-count">7.3M views</div>
        </div>
      </div>
    );
  }

  return (
    <div className="video-preview">
      <div className="thumbnail">
        {isVideo ? (
          <video controls src={bannerImg} className="thumbnail-image" />
        ) : (
          <img
            src={
              bannerImg ??
              "https://img.freepik.com/free-photo/vertical-shot-river-surrounded-by-mountains-meadows-scotland_181624-27881.jpg"
            }
            alt="A person speaking at a podium"
            className="thumbnail-image"
          />
        )}

        <div className="duration">9:17</div>
      </div>
      <div className="content">
        <div className="channel-icon">
          <span>UY</span>
        </div>
        <div className="info">
          <h2 className="title">{title ?? ""}</h2>
          <p className="post-title-hashtags">{hashtags ?? ""}</p>
          <div className="meta">
            <span className="channel-name">UY-ol</span>
            <span className="separator">•</span>
            <span className="views">105K views</span>
            <span className="separator">•</span>
            <span className="time">4 hours ago</span>
          </div>
        </div>
        <button
          type="button"
          className="more-options"
          aria-label="More options"
          disabled
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="more-icon"
          >
            <circle cx="12" cy="12" r="1" />
            <circle cx="12" cy="5" r="1" />
            <circle cx="12" cy="19" r="1" />
          </svg>
        </button>
      </div>
    </div>
  );
};

export default YtVideoCard;
