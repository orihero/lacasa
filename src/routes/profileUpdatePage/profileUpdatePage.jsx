import { Avatar } from "@files-ui/react";
import { doc, updateDoc } from "firebase/firestore";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { assetUpload } from "../../lib/assetUpload";
import { db } from "../../lib/firebase";
import { useUserStore } from "../../lib/userStore";
import "./profileUpdatePage.scss";

function ProfileUpdatePage() {
  const [profimeImage, setProfimeImage] = useState("/avatar.jpg");

  const { currentUser, fetchUserInfo } = useUserStore();

  const navigate = useNavigate();

  const onUpdateProfile = async (e) => {
    e.preventDefault();
    const updater = async () => {
      let r = null;
      if (profimeImage !== "/avatar.jpg") {
        r = await assetUpload(profimeImage);
      }

      const formData = new FormData(e.target);
      let data = Object.fromEntries(formData);
      if (!!r) {
        data = { ...data, avatar: r };
      }
      await updateDoc(doc(db, "users", currentUser.id), data);
    };
    toast.promise(updater, {
      error: "Something went wrong!",
      pending: "Uploading",
      success: "Successfully updated",
    });
    // await fetchUserInfo();
    navigate("/profile");
  };

  return (
    <div className="profileUpdatePage">
      <div className="formContainer">
        <form onSubmit={onUpdateProfile}>
          <h1>Update Profile</h1>
          <Avatar
            src={profimeImage}
            onError={() => setProfimeImage("/avatar.jpg")}
            onChange={(imgSource) => setProfimeImage(imgSource)}
            accept=".jpg, .png, .gif, .bmp, .webp"
            alt="Avatar"
          />
          <div className="item">
            <label htmlFor="fullName">Full name</label>
            <input id="fullName" name="fullName" type="text" />
          </div>
          <div className="item">
            <label htmlFor="phoneNumber">Phone number</label>
            <input id="phoneNumber" name="phoneNumber" type="tel" />
          </div>
          <div className="item">
            <label htmlFor="email">Email</label>
            <input id="email" name="email" type="email" />
          </div>
          <div className="item">
            <label htmlFor="password">Password</label>
            <input id="password" name="password" type="password" />
          </div>
          <button>Update</button>
        </form>
      </div>
      <div className="sideContainer">
        <img src="" alt="" className="avatar" />
      </div>
    </div>
  );
}

export default ProfileUpdatePage;
