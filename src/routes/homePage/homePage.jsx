import { useEffect } from "react";
import { useListStore } from "../../lib/adsListStore";
import HorizontalList from "../horizontalList/HorizontalList";
import "./homePage.scss";

function HomePage() {
  const { fetchAdsList } = useListStore();
  useEffect(() => {
    fetchAdsList();
  }, []);

  return (
    <div className="container">
      <div className={""}>
        {/* <img src="/cards/bg1.png" alt="" /> */}
        <iframe
          width="100%"
          height="640"
          frameBorder="0"
          allow="xr-spatial-tracking; gyroscope; accelerometer"
          allowFullScreen
          scrolling="no"
          src="https://app.cloudpano.com/tours/F_bT4A587K?disable=logo,sound,ribbon,request,controls,leadgen,floorplan,watermark"
        ></iframe>
      </div>
      {/* <div className="homePage">
        <div className="textContainer">
          <div className="wrapper">
            <h1 className="title">Find Real Estate & Get Your Dream Place</h1>
            <p>
              Lorem ipsum dolor sit amet consectetur adipisicing elit. Eos
              explicabo suscipit cum eius, iure est nulla animi consequatur
              facilis id pariatur fugit quos laudantium temporibus dolor ea
              repellat provident impedit!
            </p>
            <SearchBar />
            <div className="boxes">
              <div className="box">
                <h1>16+</h1>
                <h2>Years of Experience</h2>
              </div>
              <div className="box">
                <h1>200</h1>
                <h2>Award Gained</h2>
              </div>
              <div className="box">
                <h1>2000+</h1>
                <h2>Property Ready</h2>
              </div>
            </div>
          </div>
        </div>
        <div className="imgContainer">
          <img src="/bg.png" alt="" />
        </div>
      </div> */}
      <div className="list">
        <HorizontalList />
      </div>
    </div>
  );
}

export default HomePage;
