import React from "react";
import "./ytVideoCard.scss";
const YtVideoCard = () => {
  return (
    <div className="video-preview">
      <div className="thumbnail">
        <img
          src="https://cdn.pixabay.com/photo/2023/05/06/20/15/ai-generated-7975048_640.png"
          className="thumbnail-image"
        />
        <div className="duration">9:17</div>
      </div>
      <div className="content">
        <div className="channel-icon">
          <span>UY</span>
        </div>
        <div className="info">
          <h2 className="title">Video Title - 11-noyabr kun davjesti</h2>
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
