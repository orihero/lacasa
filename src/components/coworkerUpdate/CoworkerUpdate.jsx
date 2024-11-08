import { Avatar } from "@files-ui/react";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  updateDoc,
} from "firebase/firestore";
import React, { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { toast } from "react-toastify";
import { db } from "../../lib/firebase";
import { useUserStore } from "../../lib/userStore";
import "./coworkerUpdate.scss";
import { Triangle } from "react-loader-spinner";
import { assetUpload } from "../../lib/assetUpload";
import { useNavigate, useParams } from "react-router-dom";
import { useCoworkerStore } from "../../lib/useCoworkerStore";
const CoworkerUpdate = () => {
  const { t } = useTranslation();
  const [profimeImage, setProfimeImage] = useState("/avatar.jpg");
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm();
  const { currentUser } = useUserStore();
  const { fetchCoworkerById, coworker } = useCoworkerStore();
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { id } = useParams();
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    if (id) {
      fetchCoworkerById(id, currentUser.id);
    }
  }, [id]);

  useEffect(() => {
    if (coworker) {
      reset({
        fullName: coworker.fullName || "",
        email: coworker.email || "",
        phone: coworker.phoneNumber || "",
        password: coworker.password || "",
      });
      setProfimeImage(coworker.avatar);
    }
  }, [coworker]);

  const onSubmit = async (data) => {
    setLoading(true);

    const { phone, email, password, fullName } = data;

    try {
      let r = null;
      const updater = async () => {
        if (profimeImage !== coworker.avatar) {
          r = await assetUpload(profimeImage);
        }

        const docRef = doc(db, "users", coworker.id);

        await updateDoc(docRef, {
          fullName,
          email,
          password,
          phoneNumber: phone,
          avatar: r ?? profimeImage,
          adsCount: 0,
        });

        toast.success("Coworker successfully updated!");
        navigate("/profile/" + currentUser.id + "/coworkers");
        reset(); // Reset to initial values
        setLoading(false);
      };

      toast.promise(updater, {
        error: "Something went wrong!",
        pending: "Updating",
        success: "Coworker successfully updated",
      });
    } catch (error) {
      console.error(error);
      toast.error("Error updating coworker: " + error.message);
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    setLoading(true);

    try {
      const coworkerRef = doc(db, "users", coworker.id);

      await deleteDoc(coworkerRef);

      toast.success("Coworker successfully deleted!");
      navigate("/profile/" + currentUser.id + "/coworkers");
    } catch (error) {
      console.error("Error deleting coworker:", error);
      toast.error("Error deleting coworker: " + error?.message);
    }

    setLoading(false);
  };

  const togglePasswordVisibility = () => {
    setShowPassword((prev) => !prev);
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
    navigate("/profile/" + currentUser.id + "/coworkers");
  };

  if (loading) {
    return (
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
    );
  }

  return (
    <div className="profile-setting">
      <div className="profile-header">
        <h1>Update coworker</h1>
      </div>
      <div className="profile-content">
        <div className="avatar">
          <Avatar
            src={profimeImage}
            onError={() => setProfimeImage("/avatar.jpg")}
            onChange={(imgSource) => setProfimeImage(imgSource)}
            accept=".jpg, .png, .gif, .bmp, .webp"
            alt="Avatar"
          />
        </div>
        <div className="inputs">
          <form onSubmit={handleSubmit(onSubmit)}>
            <div className="field-list">
              <div className="field">
                <label>{t("fullName")}:</label>
                <input
                  type="text"
                  {...register("fullName", {
                    required: "Full Name is required",
                  })}
                  className={errors.fullName ? "error" : ""}
                />
                {errors.fullName && <span>{errors.fullName.message}</span>}
              </div>
              <div className="field">
                <label>{t("phone")}:</label>
                <input
                  type="text"
                  {...register("phone", {
                    required: "Phone number is required",
                    pattern: {
                      value: /^\+998\d{9}$/,
                      message: "Invalid Uzbekistan phone number",
                    },
                  })}
                  className={errors.phone ? "error" : ""}
                />
                {errors.phone && <span>{errors.phone.message}</span>}
              </div>
              <div className="field">
                <label>{t("email")}:</label>
                <input
                  type="email"
                  {...register("email", { required: "Email is required" })}
                  className={errors.email ? "error" : ""}
                />
                {errors.email && <span>{errors.email.message}</span>}
              </div>

              <div className="field">
                <label>{t("password")}:</label>
                <div style={{ position: "relative" }}>
                  <input
                    type={showPassword ? "text" : "password"}
                    {...register("password", {
                      required: "Password is required",
                      minLength: {
                        value: 6,
                        message: "Password must be at least 6 characters",
                      },
                    })}
                    className={errors.password ? "error" : ""}
                  />
                  <span
                    onClick={togglePasswordVisibility}
                    style={{
                      position: "absolute",
                      right: "10px",
                      top: "17px",
                      transform: "translateY(-50%)",
                      cursor: "pointer",
                      color: "#888",
                    }}
                  >
                    {showPassword ? "👁️" : "🙈"}
                  </span>
                </div>
                {errors.password && <span>{errors.password.message}</span>}
              </div>
            </div>

            <div className="profile-btns">
              <div className="buttons">
                <button
                  className="cancel-btn"
                  type="button"
                  onClick={handleCancel}
                >
                  Cancel
                </button>
                <button type="submit">Save</button>
                <button
                  className="delete-btn"
                  type="button"
                  onClick={handleDelete}
                >
                  Delete
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default CoworkerUpdate;
