import { useState } from "react";
import { Link } from "react-router-dom";
import { useUserStore } from "../../lib/userStore";
import "./navbar.scss";
import { Triangle } from "react-loader-spinner";

function Navbar() {
  const [open, setOpen] = useState(false);

  const { currentUser, isLoading } = useUserStore();
  console.log(currentUser);

  const renderRight = () => {
    if (isLoading) {
      return (
        <Triangle
          visible={true}
          height="80"
          width="80"
          color="#4fa94d"
          ariaLabel="triangle-loading"
          wrapperStyle={{}}
          wrapperClass=""
        />
      );
    }
    if (!!currentUser) {
      return (
        <div className="user">
          <img
            src={currentUser.avatar ? currentUser.avatar : "/avatar.jpg"}
            alt=""
          />
          <span>{currentUser.fullName}</span>
          <Link to="/profile" className="profile">
            {/* <div className="notification">3</div> */}
            <span>Profile</span>
          </Link>
        </div>
      );
    }

    return (
      <>
        <a href="/login">Sign in</a>
        <a href="/register" className="register">
          Sign up
        </a>
      </>
    );
  };

  return (
    <nav>
      <div className="left">
        <a href="/" className="logo">
          <img src="/logo.png" alt="" />
          <span>LamaEstate</span>
        </a>
        <Link to="/">Home</Link>
        <Link to="/about">About</Link>
        {/* <Link to="/contact">Contact</Link> */}
        <Link to="/agents">Agents</Link>
      </div>
      <div className="right">
        {renderRight()}
        {/* {!!currentUser ? (
          <div className="user">
            <img
              src={currentUser.avatar ? currentUser.avatar : "/avatar.jpg"}
              alt=""
            />
            <span>{currentUser.fullName}</span>
            <Link to="/profile" className="profile">
              <div className="notification">3</div>
              <span>Profile</span>
            </Link>
          </div>
        ) : (
          <>
            {isLoading ? (
              <Triangle
                visible={true}
                height="80"
                width="80"
                color="#4fa94d"
                ariaLabel="triangle-loading"
                wrapperStyle={{}}
                wrapperClass=""
              />
            ) : (
              <>
                <a href="/login">Sign in</a>
                <a href="/register" className="register">
                  Sign up
                </a>
              </>
            )}
          </>
        )} */}
        <div className="menuIcon">
          <img
            src="/menu.png"
            alt=""
            onClick={() => setOpen((prev) => !prev)}
          />
        </div>
        <div className={open ? "menu active" : "menu"}>
          <a href="/">Home</a>
          <a href="/">About</a>
          <a href="/">Contact</a>
          <a href="/">Agents</a>
          <a href="/">Sign in</a>
          <a href="/">Sign up</a>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
