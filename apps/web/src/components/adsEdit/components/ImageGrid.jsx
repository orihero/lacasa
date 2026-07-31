import React from "react";
import "./ImageGrid.scss";

const ImageGrid = ({ images }) => {
  const getGridStyle = () => {
    switch (images.length) {
      case 1:
        return { gridTemplateColumns: "1fr", gridTemplateRows: "1fr" };
      case 2:
        return { gridTemplateColumns: "1fr 1fr", gridTemplateRows: "1fr" };
      case 3:
        return { gridTemplateColumns: "1fr 1fr", gridTemplateRows: "1fr 1fr" };
      case 4:
        return { gridTemplateColumns: "1fr 1fr", gridTemplateRows: "1fr 1fr" };
      case 5:
        return {
          gridTemplateColumns: "1fr 1fr",
          gridTemplateRows: "1fr 1fr 1fr",
        };
      default:
        return { gridTemplateColumns: "1fr", gridTemplateRows: "1fr" };
    }
  };

  return (
    <div className="tg-post-container-img" style={getGridStyle()}>
      {images.map((img, index) => (
        <img
          key={index}
          src={URL.createObjectURL(img.file)}
          alt={`img-${index}`}
        />
      ))}
    </div>
  );
};

export default ImageGrid;
