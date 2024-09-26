import { Link } from "react-router-dom";
import Chat from "../../components/chat/Chat";
import List from "../../components/list/List";
import { useUserStore } from "../../lib/userStore";
import "./profilePage.scss";

function ProfilePage() {
  const { currentUser } = useUserStore();

  return (
    <div className="profilePage">
      <div className="details">
        <div className="wrapper">
          <div className="title">
            <h1>User Information</h1>
            <Link to={"/updateProfile"}>
              <button>Update Profile</button>
            </Link>
          </div>
          <div className="info">
            <span>
              Avatar:
              <img src={currentUser?.avatar || "/avatar.jpg"} alt="" />
            </span>
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
          <div className="title">
            <h1>My List</h1>
            <Link to={"/post"}>
              <button>Create New Post</button>
            </Link>
          </div>
          <List />
          <div className="title">
            <h1>Saved List</h1>
          </div>
          <List />
        </div>
      </div>
      <div className="chatContainer">
        <div className="wrapper">
          <Chat />
        </div>
      </div>
    </div>
  );
}

export default ProfilePage;
