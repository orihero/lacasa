import React, { useRef, useState } from "react";
import "./imageCarusel.scss";
import { Galleria } from "primereact/galleria";

const ImageCarusel = ({ items }) => {
  const itemTemplate = (item) => {
    return <img src={item} style={{ width: "100%" }} />;
  };
  const indicatorTemplate = (index) => {
    return (
      <span
        style={{
          backgroundColor: "#ddd",
          cursor: "pointer",
          width: "40px",
          height: "4px",
          display: "block",
          zIndex: 10,
          margin: "5px 10px",
        }}
      ></span>
    );
  };

  return (
    <div className="card">
      <Galleria
        value={items}
        style={{ width: "100%" }}
        changeItemOnIndicatorHover
        showThumbnails={false}
        showIndicators
        item={itemTemplate}
        indicator={indicatorTemplate}
      />
    </div>
  );
};

export default ImageCarusel;
