import { Link, useNavigate } from "react-router-dom";
import List from "../../components/list/List";
import { useUserStore } from "../../lib/userStore";
import "./profilePage.scss";
import { signOut } from "firebase/auth";
import { auth } from "../../lib/firebase";
import { useEffect } from "react";
import { useListStore } from "../../lib/adsListStore";
import { Triangle } from "react-loader-spinner";

function ProfilePage() {
  const { currentUser, logout } = useUserStore();
  const { isLoading, fetchAdsByAgentId, myList } = useListStore();
  const navigate = useNavigate();

  useEffect(() => {
    if (currentUser?.id && currentUser?.role === "agent") {
      fetchAdsByAgentId(currentUser.id);
    }
  }, [currentUser?.id]);

  const handleLogout = async () => {
    await signOut(auth);
    logout();
    navigate("/");
  };

  return (
    <div className="profilePage">
      <div className="details">
        <div className="wrapper">
          <div className="title">
            <h1>User Information</h1>
            <div className="title-btn">
              <Link to={"/updateProfile"}>
                <button>Update Profile</button>
              </Link>
              <button onClick={handleLogout}>Logout</button>
            </div>
          </div>
          <div className="info">
            <div>
              <span>
                Full name: <b>{currentUser?.fullName}</b>
              </span>
              <span>
                E-mail: <b>{currentUser?.email}</b>
              </span>
              <span>
                Phone: <b>{currentUser?.phoneNumber}</b>
              </span>
            </div>
            <div>
              <span>
                <img src={currentUser?.avatar || "/avatar.jpg"} alt="" />
              </span>
            </div>
          </div>
          {currentUser?.role === "agent" ? (
            <>
              <div className="title">
                <h1>My List</h1>
                <Link to={"/post"}>
                  <button>Create New Post</button>
                </Link>
              </div>
              <List data={myList} />
            </>
          ) : (
            <>
              {!isLoading ? (
                <>
                  <div className="title">
                    <h1>Saved List</h1>
                  </div>
                  <List />
                </>
              ) : (
                <div className="loading">
                  <Triangle
                    visible={true}
                    height="80"
                    width="80"
                    color="#4fa94d"
                    ariaLabel="triangle-loading"
                    wrapperStyle={{}}
                    wrapperClass=""
                  />
                </div>
              )}
            </>
          )}
        </div>
      </div>
      <div className="chatContainer">
        <div className="wrapper">{/* <Chat /> */}</div>
      </div>
    </div>
  );
}

export default ProfilePage;
