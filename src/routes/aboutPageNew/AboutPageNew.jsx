import React from "react";
import Head from "./components/Head";
import About from "./components/About";
import Features from "./components/Features";
import Convenient from "./components/Convenient";
import Pricing from "./components/Pricing";
import Services from "./components/Services";
import Questions from "./components/Questions";
import Clients from "./components/Clients";
import ContactUs from "./components/ContactUs";
// import Footer from "./components/Footer";

const AboutPageNew = () => {
  return (
    <div className="mx-auto about-page">
      <Head />
      <About />
      <Features />
      <Convenient />
      <Pricing />
      <Services />
      <Questions />
      {/* <Clients /> */}
      <ContactUs />
    </div>
  );
};

export default AboutPageNew;
