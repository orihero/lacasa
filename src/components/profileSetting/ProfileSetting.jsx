import React, { useState } from "react";
import "./profileSetting.scss";
import { Avatar } from "@files-ui/react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import FormGroup from "@mui/material/FormGroup";
import FormControlLabel from "@mui/material/FormControlLabel";
import Switch from "@mui/material/Switch";
import { useUserStore } from "../../lib/userStore";
const ProfileSetting = () => {
  const { t } = useTranslation();
  const { currentUser } = useUserStore();
  const [profimeImage, setProfimeImage] = useState("/avatar.jpg");
  const [isEditing, setIsEditing] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm({
    defaultValues: {
      avatar: "", // Here you can set default image URL if available
      firstName: "John",
      lastName: "Doe",
      phone: "+998901234567",
      email: "john.doe@example.com",
      password: "",
      confirmPassword: "",
    },
  });

  const onSubmit = (data) => {
    console.log("Updated Data:", data);
    setIsEditing(false);
  };

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
    setIsEditing(false);
  };

  return (
    <div className="profile-setting">
      <div className="profile-header">
        <h1>Profile Setting</h1>
      </div>
      <div className="profile-container">
        <div className="left">
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
                    disabled={!isEditing}
                    {...register("firstName", {
                      required: "First name is required",
                    })}
                    className={errors.firstName ? "error" : ""}
                  />
                  {errors.firstName && <span>{errors.firstName.message}</span>}
                </div>
                <div className="field">
                  <label>{t("phone")}:</label>
                  <input
                    type="text"
                    disabled={!isEditing}
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
                    disabled={!isEditing}
                    {...register("email", { required: "Email is required" })}
                    className={errors.email ? "error" : ""}
                  />
                  {errors.email && <span>{errors.email.message}</span>}
                </div>

                <div className="field">
                  <label>{t("password")}:</label>
                  <input
                    type="password"
                    disabled={!isEditing}
                    {...register("password", {
                      required: isEditing ? "Password is required" : false,
                      minLength: {
                        value: 6,
                        message: "Password must be at least 6 characters",
                      },
                    })}
                    className={errors.password ? "error" : ""}
                  />
                  {errors.password && <span>{errors.password.message}</span>}
                </div>
                <div className="field">
                  <label>{t("password")}:</label>
                  <input
                    type="password"
                    disabled={!isEditing}
                    {...register("confirmPassword", {
                      required: isEditing
                        ? "Confirm password is required"
                        : false,
                      validate: (value) =>
                        value === watch("password") || "Passwords do not match",
                    })}
                    className={errors.confirmPassword ? "error" : ""}
                  />
                  {errors.confirmPassword && (
                    <span>{errors.confirmPassword.message}</span>
                  )}
                </div>
              </div>

              <div className="profile-btns">
                {isEditing ? (
                  <div className="buttons">
                    <button
                      className="cancel-btn"
                      type="button"
                      onClick={handleCancel}
                    >
                      Cancel
                    </button>
                    <button type="submit">Save</button>
                  </div>
                ) : (
                  <button type="button" onClick={handleEdit}>
                    Update
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
        {currentUser.role == "agent" && (
          <div className="right">
            <FormGroup>
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Instagram post yaratish"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Telegram post yaratish"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Youtube post yaratish"
              />
            </FormGroup>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProfileSetting;
